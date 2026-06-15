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
                UCard(title: "Nouveau mot de passe", icon: "key.fill") {
                    VStack(spacing: 18) {
                        UText(
                            text: "Saisissez le code reçu par email, puis choisissez un nouveau mot de passe.",
                            type: .description
                        )
                        .foregroundStyle(AppPalette.Neutral.textSecondary)

                        UTextField(
                            label: "Code de vérification",
                            placeholder: "Code à 6 chiffres",
                            icon: "number.circle.fill",
                            text: Binding(
                                get: { viewModel.verificationCode },
                                set: { viewModel.updateVerificationCode($0) }
                            ),
                            usesOneTimeCodeAutofill: true,
                            errorMessage: viewModel.validationMessage,
                            helperText: "Le système peut suggérer le code reçu par email au-dessus du clavier."
                        )

                        UTextField(
                            label: "Mot de passe",
                            placeholder: "Nouveau mot de passe",
                            icon: "lock.fill",
                            text: $viewModel.password,
                            isSecure: true,
                            isPasswordVisible: $viewModel.isPasswordVisible,
                            textContentType: .newPassword
                        )

                        UTextField(
                            label: "Confirmation",
                            placeholder: "Confirmer le mot de passe",
                            icon: "lock.rotation",
                            text: $viewModel.confirmPassword,
                            isSecure: true,
                            isPasswordVisible: $viewModel.isConfirmPasswordVisible,
                            textContentType: .newPassword
                        )

                        UButton(
                            text: viewModel.isLoading ? "Mise à jour..." : "Réinitialiser le mot de passe",
                            textColor: AppPalette.Primary.onMain,
                            backgroundColor: AppPalette.Primary.main,
                            cornerRadius: 30,
                            isFullWidth: true,
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
        .navigationTitle("Réinitialisation")
        .navigationBarTitleDisplayMode(.inline)
        .alert(
            "Mot de passe mis à jour",
            isPresented: Binding(
                get: { viewModel.successMessage != nil },
                set: { if !$0 { viewModel.successMessage = nil } }
            )
        ) {
            Button("Retour à la connexion") {
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
