//
//  ResetPasswordViewModel.swift
//  LeVestaire
//
//  Created by Corentin Robert on 15/06/2026.
//

import Combine
import Foundation

@MainActor
final class ResetPasswordViewModel: ObservableObject {
    let resetToken: String?

    @Published var verificationCode = ""
    @Published var password = ""
    @Published var confirmPassword = ""
    @Published var isPasswordVisible = false
    @Published var isConfirmPasswordVisible = false
    @Published var validationMessage: String?
    @Published var successMessage: String?
    @Published var isLoading = false

    private let authService: AuthService

    init(resetToken: String?, authService: AuthService) {
        self.resetToken = resetToken
        self.authService = authService
    }

    convenience init(resetToken: String? = nil) {
        self.init(resetToken: resetToken, authService: AuthService.shared)
    }

    var canSubmit: Bool {
        !verificationCode.trimmingCharacters(in: .whitespaces).isEmpty
            && !password.isEmpty
            && !confirmPassword.isEmpty
            && !isLoading
    }

    func updateVerificationCode(_ input: String) {
        let filtered = input.filter(\.isNumber)
        if filtered.count <= 8 {
            verificationCode = filtered
        }
    }

    func resetPassword() {
        validationMessage = nil
        successMessage = nil

        guard canSubmit else {
            validationMessage = "Veuillez remplir tous les champs."
            return
        }

        guard password == confirmPassword else {
            validationMessage = "Les mots de passe ne correspondent pas."
            return
        }

        guard password.count >= 8 else {
            validationMessage = "Le mot de passe doit contenir au moins 8 caractères."
            return
        }

        let token = resolvedResetToken
        guard !token.isEmpty else {
            validationMessage = "Veuillez saisir le code reçu par email."
            return
        }

        isLoading = true

        Task {
            defer { isLoading = false }

            let response = await authService.confirmPasswordReset(
                token: token,
                newPassword: password
            )

            if response.success {
                successMessage = response.message ?? "Votre mot de passe a été mis à jour avec succès."
                return
            }

            validationMessage = response.error ?? response.message ?? "Impossible de réinitialiser le mot de passe."
        }
    }

    private var resolvedResetToken: String {
        let deepLinkToken = resetToken?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        if !deepLinkToken.isEmpty {
            return deepLinkToken
        }

        return verificationCode.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
