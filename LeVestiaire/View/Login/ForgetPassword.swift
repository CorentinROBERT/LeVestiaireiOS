//
//  ForgetPassword.swift
//  LeVestaire
//
//  Created by Corentin Robert on 15/06/2026.
//

import SwiftUI

struct ForgetPassword: View {
    @StateObject private var viewModel = ForgetPasswordViewModel()
    let onNavigateToResetPassword: () -> Void

    init(onNavigateToResetPassword: @escaping () -> Void = {}) {
        self.onNavigateToResetPassword = onNavigateToResetPassword
    }

    var body: some View {
        ZStack {
            AuthScreenBackground()

            ScrollView(showsIndicators: false) {
                UCard(title: L10n.forgotPassword, icon: "lock.fill") {
                    VStack(spacing: 18) {
                        UText(
                            text: L10n.forgetPasswordDescription,
                            type: .description
                        )
                        .foregroundStyle(AppPalette.Neutral.textSecondary)

                        UTextField(
                            label: L10n.email,
                            placeholder: L10n.emailAddress,
                            icon: "envelope.fill",
                            text: $viewModel.email,
                            keyboardType: .emailAddress,
                            textContentType: .emailAddress,
                            errorMessage: viewModel.validationMessage,
                            helperText: L10n.forgetPasswordEmailHelper,
                            accessibilityIdentifier: AccessibilityID.Auth.forgetPasswordEmailField
                        )

                        UButton(
                            text: viewModel.isLoading ? L10n.sendingInProgress : L10n.confirm,
                            textColor: AppPalette.Primary.onMain,
                            backgroundColor: AppPalette.Primary.main,
                            cornerRadius: 30,
                            isFullWidth: true,
                            accessibilityIdentifier: AccessibilityID.Auth.forgetPasswordSubmit,
                            onPress: viewModel.submit
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
        .navigationTitle(L10n.forgotPassword)
        .navigationBarTitleDisplayMode(.inline)
        .alert(
            L10n.passwordResetEmailSentTitle,
            isPresented: Binding(
                get: { viewModel.successMessage != nil },
                set: { if !$0 { viewModel.successMessage = nil } }
            )
        ) {
            Button(L10n.continueButton) {
                viewModel.successMessage = nil
                onNavigateToResetPassword()
            }
        } message: {
            Text(viewModel.successMessage ?? "")
        }
    }
}

#Preview {
    NavigationStack {
        ForgetPassword()
    }
}
