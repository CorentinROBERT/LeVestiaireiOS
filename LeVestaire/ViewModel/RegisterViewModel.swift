//
//  RegisterViewModel.swift
//  LeVestaire
//
//  Created by Corentin Robert on 14/06/2026.
//

import Combine
import Foundation

final class RegisterViewModel: ObservableObject {
    @Published var lastName = ""
    @Published var firstName = ""
    @Published var email = ""
    @Published var password = ""
    @Published var confirmPassword = ""
    @Published var isPasswordVisible = false
    @Published var isConfirmPasswordVisible = false
    @Published var birthDate = Calendar.current.date(byAdding: .year, value: -18, to: Date()) ?? Date()
    @Published var selectedLanguage: AppLanguage = .french
    @Published var hasAcceptedLegalTerms = false
    @Published var validationMessage: String?
    @Published var showEmailVerification = false

    var canSubmit: Bool {
        !lastName.trimmingCharacters(in: .whitespaces).isEmpty
            && !firstName.trimmingCharacters(in: .whitespaces).isEmpty
            && !email.trimmingCharacters(in: .whitespaces).isEmpty
            && !password.isEmpty
            && !confirmPassword.isEmpty
            && hasAcceptedLegalTerms
    }

    func createAccount() {
        validationMessage = nil

        guard canSubmit else {
            validationMessage = "Veuillez remplir tous les champs et accepter les documents légaux."
            return
        }

        guard isValidEmail(email) else {
            validationMessage = "L'adresse email n'est pas valide."
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

        guard birthDate <= Date() else {
            validationMessage = "La date de naissance n'est pas valide."
            return
        }

        // TODO: appeler l'API d'inscription
        showEmailVerification = true
    }

    private func isValidEmail(_ email: String) -> Bool {
        let pattern = #"^[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$"#
        return email.range(of: pattern, options: .regularExpression) != nil
    }
}
