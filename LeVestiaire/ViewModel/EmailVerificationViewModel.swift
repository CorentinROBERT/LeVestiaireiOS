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
    private let authService: AuthService
    private let pendingCredentialsStore: PendingAuthCredentialsStore

    var canResendEmail: Bool {
        resendCooldownRemaining == 0 && !isResending
    }

    init(
        email: String,
        authService: AuthService,
        pendingCredentialsStore: PendingAuthCredentialsStore
    ) {
        self.email = email
        self.authService = authService
        self.pendingCredentialsStore = pendingCredentialsStore
    }

    convenience init(email: String) {
        self.init(
            email: email,
            authService: AuthService.shared,
            pendingCredentialsStore: PendingAuthCredentialsStore.shared
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
                    feedbackMessage = "Votre email n'est pas encore vérifié. Consultez votre boîte mail et réessayez."
                }
                return
            }

            let didSignIn = await signInAfterVerification()
            if !didSignIn, feedbackMessage == nil {
                feedbackMessage = "Connexion automatique impossible après vérification."
            }
        }
    }

    private func checkEmailVerificationStatus() async -> Bool {
        let response = await authService.checkEmailVerification(email: email)

        if response.success, response.emailVerified == true {
            return true
        }

        if let message = response.message, !message.isEmpty {
            feedbackMessage = message
        }

        return false
    }

    private func signInAfterVerification() async -> Bool {
        if authService.isAuthenticated {
            return true
        }

        guard let credentials = pendingCredentialsStore.load(),
              credentials.email.caseInsensitiveCompare(email) == .orderedSame else {
            feedbackMessage = "Connexion automatique impossible. Veuillez vous connecter manuellement."
            return false
        }

        let response = await authService.login(email: credentials.email, password: credentials.password)

        if response.success && response.hasValidData {
            pendingCredentialsStore.clear()
            return true
        }

        feedbackMessage = response.message ?? response.error ?? "Connexion automatique impossible après vérification."
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
                feedbackMessage = response.message ?? "Un nouvel email de vérification a été envoyé."
                startResendCooldown()
                return
            }

            feedbackMessage = response.message ?? response.error ?? "Impossible de renvoyer l'email de vérification."
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
