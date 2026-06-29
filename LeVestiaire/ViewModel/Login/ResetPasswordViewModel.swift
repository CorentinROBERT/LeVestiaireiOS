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

    private let authService: any AuthServicing

    init(resetToken: String?, authService: any AuthServicing) {
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
            validationMessage = L10n.fillAllFields
            return
        }

        guard password == confirmPassword else {
            validationMessage = L10n.passwordsDoNotMatch
            return
        }

        guard password.count >= 8 else {
            validationMessage = L10n.passwordMin8Characters
            return
        }

        let token = resolvedResetToken
        guard !token.isEmpty else {
            validationMessage = L10n.enterResetCode
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
                successMessage = L10n.apiMessage(response.message) ?? L10n.passwordUpdatedSuccessfully
                return
            }

            validationMessage = L10n.apiErrorMessage(
                message: response.message,
                error: response.error,
                fallback: L10n.resetPasswordFailed
            )
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
