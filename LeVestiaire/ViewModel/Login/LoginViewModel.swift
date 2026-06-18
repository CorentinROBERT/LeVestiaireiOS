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
    private static let developerAccessPassword = "asdescopains"
    private static let developerTapThreshold = 5
    private static let developerTapResetInterval: TimeInterval = 2

    @Published var email = ""
    @Published var password = ""
    @Published var isPasswordVisible = false
    @Published var showDeveloperPasswordDialog = false
    @Published var showDeveloperPasswordError = false
    @Published var showDeveloperPage = false
    @Published var developerPasswordInput = ""
    @Published var validationMessage: String?
    @Published var isLoading = false
    @Published var showEmailVerification = false

    private var developerTapCount = 0
    private var lastDeveloperTapDate: Date?
    private var cancellables = Set<AnyCancellable>()
    private let authService: AuthService
    private let savedEmailStore: SavedLoginEmailStore
    private let pendingCredentialsStore: PendingAuthCredentialsStore
    private let biometricStore: BiometricAuthStore

    var trimmedEmail: String {
        email.trimmed
    }

    init(
        authService: AuthService,
        savedEmailStore: SavedLoginEmailStore,
        pendingCredentialsStore: PendingAuthCredentialsStore,
        biometricStore: BiometricAuthStore
    ) {
        self.authService = authService
        self.savedEmailStore = savedEmailStore
        self.pendingCredentialsStore = pendingCredentialsStore
        self.biometricStore = biometricStore
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
            biometricStore: BiometricAuthStore.shared
        )
    }

    var requiresPasswordReauthentication: Bool {
        authService.requiresPasswordReauthentication
    }

    func registerDeveloperTap() {
        let now = Date()

        if let lastTap = lastDeveloperTapDate,
           now.timeIntervalSince(lastTap) > Self.developerTapResetInterval {
            developerTapCount = 0
        }

        lastDeveloperTapDate = now
        developerTapCount += 1

        guard developerTapCount >= Self.developerTapThreshold else { return }

        developerTapCount = 0
        developerPasswordInput = ""
        showDeveloperPasswordDialog = true
    }

    func validateDeveloperPassword() {
        guard developerPasswordInput == Self.developerAccessPassword else {
            showDeveloperPasswordDialog = false
            developerPasswordInput = ""
            showDeveloperPasswordError = true
            return
        }

        showDeveloperPasswordDialog = false
        developerPasswordInput = ""
        showDeveloperPage = true
    }

    func cancelDeveloperPassword() {
        developerPasswordInput = ""
        showDeveloperPasswordDialog = false
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
