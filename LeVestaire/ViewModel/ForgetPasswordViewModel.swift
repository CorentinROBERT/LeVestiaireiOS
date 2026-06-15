//
//  ForgetPasswordViewModel.swift
//  LeVestaire
//
//  Created by Corentin Robert on 15/06/2026.
//

import Combine
import Foundation

final class ForgetPasswordViewModel: ObservableObject {
    @Published var email = ""
    @Published var validationMessage: String?
    @Published var successMessage: String?
    @Published var isLoading = false

    var canSubmit: Bool {
        !email.trimmingCharacters(in: .whitespaces).isEmpty && !isLoading
    }

    func submit() {
        validationMessage = nil
        successMessage = nil

        let trimmedEmail = email.trimmingCharacters(in: .whitespaces)

        guard !trimmedEmail.isEmpty else {
            validationMessage = "Veuillez saisir votre adresse email."
            return
        }

        guard isValidEmail(trimmedEmail) else {
            validationMessage = "L'adresse email n'est pas valide."
            return
        }

        isLoading = true

        Task { @MainActor in
            defer { isLoading = false }

            // TODO: appeler l'API de réinitialisation du mot de passe
            successMessage = "Un email de réinitialisation a été envoyé à \(trimmedEmail)."
        }
    }

    private func isValidEmail(_ email: String) -> Bool {
        let pattern = #"^[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$"#
        return email.range(of: pattern, options: .regularExpression) != nil
    }
}
