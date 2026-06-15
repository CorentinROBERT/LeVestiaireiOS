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
                UCard(title: "Mot de passe oublié", icon: "lock.fill") {
                    VStack(spacing: 18) {
                        UText(
                            text: "Saisissez l'email associé à votre compte pour recevoir un lien de réinitialisation.",
                            type: .description
                        )
                        .foregroundStyle(AppPalette.Neutral.textSecondary)

                        UTextField(
                            label: "Email",
                            placeholder: "Adresse email",
                            icon: "envelope.fill",
                            text: $viewModel.email,
                            keyboardType: .emailAddress,
                            textContentType: .emailAddress,
                            errorMessage: viewModel.validationMessage,
                            helperText: "Merci de renseigner l'email utilisé lors de votre inscription."
                        )

                        UButton(
                            text: viewModel.isLoading ? "Envoi en cours..." : "Confirmer",
                            textColor: AppPalette.Primary.onMain,
                            backgroundColor: AppPalette.Primary.main,
                            cornerRadius: 30,
                            isFullWidth: true,
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
        .navigationTitle("Mot de passe oublié")
        .navigationBarTitleDisplayMode(.inline)
        .alert(
            "Email envoyé",
            isPresented: Binding(
                get: { viewModel.successMessage != nil },
                set: { if !$0 { viewModel.successMessage = nil } }
            )
        ) {
            Button("Continuer") {
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
