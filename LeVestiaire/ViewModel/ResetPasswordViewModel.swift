//
//  ResetPasswordViewModel.swift
//  LeVestaire
//
//  Created by Corentin Robert on 15/06/2026.
//

import Combine
import Foundation

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

    init(resetToken: String? = nil) {
        self.resetToken = resetToken
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

        guard !verificationCode.trimmingCharacters(in: .whitespaces).isEmpty else {
            validationMessage = "Veuillez saisir le code reçu par email."
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

        // Le token est fourni par le lien reçu par email (deep link).
        // En navigation in-app depuis ForgetPassword, il peut être nil tant que l'API n'est pas branchée.
        if let resetToken, resetToken.isEmpty {
            validationMessage = "Le lien de réinitialisation est invalide ou expiré."
            return
        }

        isLoading = true

        Task { @MainActor in
            defer { isLoading = false }

            // TODO: appeler l'API avec verificationCode, resetToken et nouveau mot de passe
            successMessage = "Votre mot de passe a été mis à jour avec succès."
        }
    }
}
