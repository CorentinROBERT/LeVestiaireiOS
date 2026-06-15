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
    private let authService: AuthService

    init(authService: AuthService) {
        self.authService = authService
    }

    convenience init() {
        self.init(authService: AuthService.shared)
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

        let trimmedEmail = email.trimmingCharacters(in: .whitespaces)

        guard !trimmedEmail.isEmpty else {
            validationMessage = "Veuillez saisir votre adresse email."
            return
        }

        guard !password.isEmpty else {
            validationMessage = "Veuillez saisir votre mot de passe."
            return
        }

        isLoading = true

        Task {
            defer { isLoading = false }

            let response = await authService.login(email: trimmedEmail, password: password)

            if response.success && response.hasValidData {
                return
            }

            if response.requiresVerification == true || response.isEmailVerified == false {
                showEmailVerification = true
                validationMessage = response.message ?? "Veuillez vérifier votre email avant de continuer."
                return
            }

            validationMessage = response.message ?? response.error ?? "Connexion impossible."
        }
    }
}
