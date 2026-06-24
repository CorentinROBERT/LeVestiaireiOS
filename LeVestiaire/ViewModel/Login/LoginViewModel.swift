//
//  LoginViewModel.swift
//  LeVestaire
//
//  Created by Corentin Robert on 12/06/2026.
//

import Combine
import Foundation

@MainActor
final class LoginViewModel: ObservableObject {
    @Published var email = ""
    @Published var password = ""
    @Published var isPasswordVisible = false
    @Published var validationMessage: String?
    @Published var isLoading = false
    @Published var showEmailVerification = false

    private var cancellables = Set<AnyCancellable>()
    private let authService: AuthService
    private let savedEmailStore: SavedLoginEmailStore
    private let pendingCredentialsStore: PendingAuthCredentialsStore
    private let biometricStore: BiometricAuthStore
    private let teamInviteCoordinator: TeamInviteCoordinator

    var pendingInviteTeamName: String? {
        teamInviteCoordinator.pendingInviteTeamName
    }

    var trimmedEmail: String {
        email.trimmed
    }

    init(
        authService: AuthService,
        savedEmailStore: SavedLoginEmailStore,
        pendingCredentialsStore: PendingAuthCredentialsStore,
        biometricStore: BiometricAuthStore,
        teamInviteCoordinator: TeamInviteCoordinator
    ) {
        self.authService = authService
        self.savedEmailStore = savedEmailStore
        self.pendingCredentialsStore = pendingCredentialsStore
        self.biometricStore = biometricStore
        self.teamInviteCoordinator = teamInviteCoordinator
        self.email = savedEmailStore.load() ?? ""

        authService.objectWillChange
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.objectWillChange.send()
            }
            .store(in: &cancellables)
    }

    convenience init() {
        self.init(
            authService: AuthService.shared,
            savedEmailStore: SavedLoginEmailStore.shared,
            pendingCredentialsStore: PendingAuthCredentialsStore.shared,
            biometricStore: BiometricAuthStore.shared,
            teamInviteCoordinator: .shared
        )
    }

    var requiresPasswordReauthentication: Bool {
        authService.requiresPasswordReauthentication
    }

    func login() {
        validationMessage = nil

        let trimmedEmail = trimmedEmail

        guard !trimmedEmail.isEmpty else {
            validationMessage = L10n.pleaseEnterYourEmail
            return
        }

        guard !password.isEmpty else {
            validationMessage = L10n.passwordRequired
            return
        }

        savedEmailStore.save(trimmedEmail)
        isLoading = true

        Task {
            defer { isLoading = false }
            let response = await authService.login(email: trimmedEmail, password: password)
            if response.success && response.hasValidData {
                guard authService.isAuthenticated else {
                    validationMessage = biometricStore.lastErrorMessage ?? L10n.loginFailed
                    return
                }
                _ = await teamInviteCoordinator.joinPendingTeamIfNeeded()
                return
            }
            if response.requiresVerification == true || response.isEmailVerified == false {
                pendingCredentialsStore.save(email: trimmedEmail, password: password)
                showEmailVerification = true
                validationMessage = L10n.apiErrorMessage(
                    message: response.message,
                    error: response.error,
                    fallback: L10n.verifyEmailBeforeLogin
                )
                return
            }

            validationMessage = L10n.apiErrorMessage(
                message: response.message,
                error: response.error,
                fallback: L10n.loginFailed
            )
        }
    }
}
