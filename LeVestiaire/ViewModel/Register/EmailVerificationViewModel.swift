//
//  EmailVerificationViewModel.swift
//  LeVestaire
//
//  Created by Corentin Robert on 14/06/2026.
//

import Combine
import Foundation

@MainActor
final class EmailVerificationViewModel: ObservableObject {
    private static let resendCooldownDuration = 20

    let email: String

    @Published var isCheckingVerification = false
    @Published var isResending = false
    @Published var feedbackMessage: String?
    @Published var resendCooldownRemaining = 0

    private var resendCooldownTask: Task<Void, Never>?
    private let authService: any AuthServicing
    private let pendingCredentialsStore: any PendingAuthCredentialsStoring
    private let teamInviteCoordinator: any TeamInviteCoordinating

    var canResendEmail: Bool {
        resendCooldownRemaining == 0 && !isResending
    }

    init(
        email: String,
        authService: any AuthServicing,
        pendingCredentialsStore: any PendingAuthCredentialsStoring,
        teamInviteCoordinator: any TeamInviteCoordinating
    ) {
        self.email = email
        self.authService = authService
        self.pendingCredentialsStore = pendingCredentialsStore
        self.teamInviteCoordinator = teamInviteCoordinator
    }

    convenience init(email: String) {
        self.init(
            email: email,
            authService: AuthService.shared,
            pendingCredentialsStore: PendingAuthCredentialsStore.shared,
            teamInviteCoordinator: TeamInviteCoordinator.shared
        )
    }

    deinit {
        resendCooldownTask?.cancel()
    }

    func confirmVerification() {
        guard !isCheckingVerification else { return }

        isCheckingVerification = true
        feedbackMessage = nil

        Task {
            defer { isCheckingVerification = false }

            let isVerified = await checkEmailVerificationStatus()
            guard isVerified else {
                if feedbackMessage == nil {
                    feedbackMessage = L10n.emailNotYetVerified
                }
                return
            }

            let didSignIn = await signInAfterVerification()
            if !didSignIn, feedbackMessage == nil {
                feedbackMessage = L10n.autoLoginFailedAfterVerification
            }
        }
    }

    private func checkEmailVerificationStatus() async -> Bool {
        let response = await authService.checkEmailVerification(email: email)

        if response.success, response.emailVerified == true {
            return true
        }

        if let message = response.message, !message.isEmpty {
            feedbackMessage = L10n.apiMessage(message) ?? message
        }

        return false
    }

    private func signInAfterVerification() async -> Bool {
        if authService.isAuthenticated {
            _ = await teamInviteCoordinator.joinPendingTeamIfNeeded()
            return true
        }

        guard let credentials = pendingCredentialsStore.load(),
              credentials.email.caseInsensitiveCompare(email) == .orderedSame else {
            feedbackMessage = L10n.autoLoginFailedManual
            return false
        }

        let response = await authService.login(email: credentials.email, password: credentials.password)

        if response.success && response.hasValidData {
            pendingCredentialsStore.clear()
            _ = await teamInviteCoordinator.joinPendingTeamIfNeeded()
            return true
        }

        feedbackMessage = L10n.apiErrorMessage(
            message: response.message,
            error: response.error,
            fallback: L10n.autoLoginFailedAfterVerification
        )
        return false
    }

    func resendEmail() {
        guard canResendEmail else { return }

        isResending = true
        feedbackMessage = nil

        Task {
            defer { isResending = false }

            let response = await authService.resendVerificationEmail(email: email)

            if response.success {
                feedbackMessage = L10n.apiMessage(response.message) ?? L10n.verificationEmailResent
                startResendCooldown()
                return
            }

            feedbackMessage = L10n.apiErrorMessage(
                message: response.message,
                error: response.error,
                fallback: L10n.verificationEmailResendFailed
            )
        }
    }

    private func startResendCooldown() {
        resendCooldownTask?.cancel()
        resendCooldownRemaining = Self.resendCooldownDuration

        resendCooldownTask = Task {
            while resendCooldownRemaining > 0 {
                try? await Task.sleep(nanoseconds: 1_000_000_000)
                guard !Task.isCancelled else { return }
                resendCooldownRemaining -= 1
            }
        }
    }
}
