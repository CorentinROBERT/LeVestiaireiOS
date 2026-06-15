//
//  RegisterViewModel.swift
//  LeVestaire
//
//  Created by Corentin Robert on 14/06/2026.
//

import Combine
import Foundation

@MainActor
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
    @Published var isLoading = false

    private let authService: AuthService

    init(authService: AuthService) {
        self.authService = authService
    }

    convenience init() {
        self.init(authService: AuthService.shared)
    }

    var canSubmit: Bool {
        !lastName.trimmingCharacters(in: .whitespaces).isEmpty
            && !firstName.trimmingCharacters(in: .whitespaces).isEmpty
            && !email.trimmingCharacters(in: .whitespaces).isEmpty
            && !password.isEmpty
            && !confirmPassword.isEmpty
            && hasAcceptedLegalTerms
            && !isLoading
    }

    func createAccount() {
        validationMessage = nil

        guard canSubmit else {
            validationMessage = "Veuillez remplir tous les champs et accepter les documents légaux."
            return
        }

        let trimmedEmail = email.trimmingCharacters(in: .whitespaces)

        guard isValidEmail(trimmedEmail) else {
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

        isLoading = true

        Task {
            defer { isLoading = false }

            let response = await authService.register(
                email: trimmedEmail,
                password: password,
                firstName: firstName.trimmingCharacters(in: .whitespaces),
                lastName: lastName.trimmingCharacters(in: .whitespaces),
                birthDate: birthDate,
                language: selectedLanguage.rawValue
            )

            if response.success {
                showEmailVerification = true
                return
            }

            validationMessage = response.message ?? response.error ?? "Inscription impossible."
        }
    }

    private func isValidEmail(_ email: String) -> Bool {
        let pattern = #"^[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$"#
        return email.range(of: pattern, options: .regularExpression) != nil
    }
}
