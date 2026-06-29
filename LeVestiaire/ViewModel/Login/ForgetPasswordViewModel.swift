//
//  ForgetPasswordViewModel.swift
//  LeVestaire
//
//  Created by Corentin Robert on 15/06/2026.
//

import Combine
import Foundation

@MainActor
final class ForgetPasswordViewModel: ObservableObject {
    @Published var email = ""
    @Published var validationMessage: String?
    @Published var successMessage: String?
    @Published var isLoading = false

    private let authService: any AuthServicing

    init(authService: any AuthServicing) {
        self.authService = authService
    }

    convenience init() {
        self.init(authService: AuthService.shared)
    }

    var canSubmit: Bool {
        !email.trimmed.isEmpty && !isLoading
    }

    func submit() {
        validationMessage = nil
        successMessage = nil

        let trimmedEmail = email.trimmed

        guard !trimmedEmail.isEmpty else {
            validationMessage = L10n.pleaseEnterYourEmail
            return
        }

        guard trimmedEmail.isValidEmail else {
            validationMessage = L10n.emailInvalid
            return
        }

        isLoading = true

        Task {
            defer { isLoading = false }

            let response = await authService.requestPasswordReset(email: trimmedEmail)

            if response.success {
                successMessage = L10n.apiMessage(response.message)
                    ?? L10n.passwordResetEmailSentDefault(trimmedEmail)
                return
            }

            validationMessage = L10n.apiErrorMessage(
                message: response.message,
                error: response.error,
                fallback: L10n.passwordResetRequestFailed
            )
        }
    }
}
