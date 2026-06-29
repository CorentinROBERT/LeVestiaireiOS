//
//  ResetPassword.swift
//  LeVestaire
//
//  Created by Corentin Robert on 15/06/2026.
//

import SwiftUI

struct ResetPassword: View {
    @StateObject private var viewModel: ResetPasswordViewModel
    let onFinished: () -> Void

    init(resetToken: String? = nil, onFinished: @escaping () -> Void = {}) {
        _viewModel = StateObject(wrappedValue: ResetPasswordViewModel(resetToken: resetToken))
        self.onFinished = onFinished
    }

    var body: some View {
        ZStack {
            AuthScreenBackground()

            ScrollView(showsIndicators: false) {
                UCard(title: L10n.newPassword, icon: "key.fill") {
                    VStack(spacing: 18) {
                        UText(
                            text: L10n.resetPasswordInstructions,
                            type: .description
                        )
                        .foregroundStyle(AppPalette.Neutral.textSecondary)

                        UTextField(
                            label: L10n.verificationCodeLabel,
                            placeholder: L10n.verificationCodePlaceholder,
                            icon: "number.circle.fill",
                            text: Binding(
                                get: { viewModel.verificationCode },
                                set: { viewModel.updateVerificationCode($0) }
                            ),
                            usesOneTimeCodeAutofill: true,
                            errorMessage: viewModel.validationMessage,
                            helperText: L10n.verificationCodeHelper
                        )

                        UTextField(
                            label: L10n.password,
                            placeholder: L10n.newPassword,
                            icon: "lock.fill",
                            text: $viewModel.password,
                            isSecure: true,
                            isPasswordVisible: $viewModel.isPasswordVisible,
                            textContentType: .newPassword,
                            accessibilityIdentifier: AccessibilityID.Auth.resetPasswordField
                        )

                        UTextField(
                            label: L10n.confirmationLabel,
                            placeholder: L10n.confirmPassword,
                            icon: "lock.rotation",
                            text: $viewModel.confirmPassword,
                            isSecure: true,
                            isPasswordVisible: $viewModel.isConfirmPasswordVisible,
                            textContentType: .newPassword,
                            accessibilityIdentifier: AccessibilityID.Auth.resetPasswordConfirmField
                        )

                        UButton(
                            text: viewModel.isLoading ? L10n.resetPasswordUpdating : L10n.resetPassword,
                            textColor: AppPalette.Primary.onMain,
                            backgroundColor: AppPalette.Primary.main,
                            cornerRadius: 30,
                            isFullWidth: true,
                            accessibilityIdentifier: AccessibilityID.Auth.resetPasswordSubmit,
                            onPress: viewModel.resetPassword
                        )
                        .opacity(viewModel.canSubmit ? 1 : 0.5)
                        .disabled(!viewModel.canSubmit)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 24)
            }
            .scrollDismissesKeyboard(.interactively)
        }
        .navigationTitle(L10n.resetPasswordNavTitle)
        .navigationBarTitleDisplayMode(.inline)
        .alert(
            L10n.resetPasswordSuccessAlertTitle,
            isPresented: Binding(
                get: { viewModel.successMessage != nil },
                set: { if !$0 { viewModel.successMessage = nil } }
            )
        ) {
            Button(L10n.backToLogin) {
                viewModel.successMessage = nil
                onFinished()
            }
        } message: {
            Text(viewModel.successMessage ?? "")
        }
    }
}

#Preview {
    NavigationStack {
        ResetPassword(resetToken: "preview-token")
    }
}
