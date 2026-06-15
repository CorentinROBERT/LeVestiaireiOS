//
//  Login.swift
//  LeVestaire
//
//  Created by Corentin Robert on 12/06/2026.
//

import SwiftUI

struct Login: View {
    @StateObject private var viewModel = LoginViewModel()
    @State private var navigationPath = NavigationPath()

    var body: some View {
        NavigationStack(path: $navigationPath) {
            loginContent
                .navigationDestination(for: AuthFlowRoute.self) { route in
                    switch route {
                    case .register:
                        RegisterView()
                    case .forgetPassword:
                        ForgetPassword {
                            navigationPath.append(AuthFlowRoute.resetPassword(token: nil))
                        }
                    case .resetPassword(let token):
                        ResetPassword(resetToken: token) {
                            navigationPath = NavigationPath()
                        }
                    }
                }
        }
    }

    private var loginContent: some View {
        ZStack {
            AuthScreenBackground()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 28) {
                    header
                    formCard
                    secondaryActions
                }
                .padding(.horizontal, 24)
                .padding(.top, 72)
                .padding(.bottom, 56)
            }
            .scrollDismissesKeyboard(.interactively)

            VStack {
                Spacer()
                Text(AppInfo.versionLabel)
                    .font(.caption)
                    .foregroundStyle(AppPalette.Neutral.textTertiary)
            }
            .safeAreaPadding(.bottom, 10)
        }
        .ignoresSafeArea()
        .alert("Mode développeur", isPresented: $viewModel.showDeveloperPasswordDialog) {
            SecureField("Mot de passe", text: $viewModel.developerPasswordInput)
            Button("Valider") {
                viewModel.validateDeveloperPassword()
            }
            Button("Annuler", role: .cancel) {
                viewModel.cancelDeveloperPassword()
            }
        } message: {
            Text("Entrez le mot de passe pour accéder aux outils développeur.")
        }
        .alert("Accès refusé", isPresented: $viewModel.showDeveloperPasswordError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("Mot de passe incorrect.")
        }
        .fullScreenCover(isPresented: $viewModel.showDeveloperPage) {
            DeveloperView()
        }
    }

    private var header: some View {
        VStack(spacing: 14) {
            Image(systemName: "sportscourt.fill")
                .font(.system(size: 34, weight: .semibold))
                .foregroundStyle(AppPalette.Primary.main)
                .frame(width: 72, height: 72)
                .glassEffect(.regular, in: .circle)
                .contentShape(Circle())
                .onTapGesture {
                    viewModel.registerDeveloperTap()
                }

            UText(text: "Le Vestiaire", type: .title)
                .foregroundColor(AppPalette.Primary.dark)

            UText(
                text: "Connectez-vous pour gérer vos équipes",
                type: .description
            )
            .foregroundColor(AppPalette.Neutral.textSecondary)
            .multilineTextAlignment(.center)
        }
    }

    private var formCard: some View {
        VStack(spacing: 18) {
            UGlassTextField(
                placeholder: "Adresse email",
                icon: "envelope.fill",
                text: $viewModel.email,
                style: .light,
                keyboardType: .emailAddress,
                textContentType: .emailAddress
            )

            UGlassTextField(
                placeholder: "Mot de passe",
                icon: "lock.fill",
                text: $viewModel.password,
                style: .light,
                isSecure: true,
                isPasswordVisible: $viewModel.isPasswordVisible,
                textContentType: .password
            )

            UButton(
                text: "Se connecter",
                textColor: AppPalette.Primary.onMain,
                backgroundColor: AppPalette.Primary.main,
                cornerRadius: 25,
                isFullWidth: true,
                trailingIcon: "arrow.right",
                onPress: viewModel.login
            )
            .padding(.top, 4)
        }
        .padding(22)
        .glassEffect(.regular, in: .rect(cornerRadius: 28))
    }

    private var secondaryActions: some View {
        VStack(spacing: 18) {
            Button {
                navigationPath.append(AuthFlowRoute.forgetPassword)
            } label: {
                Text("Mot de passe oublié ?")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(AppPalette.Primary.main)
            }
            .buttonStyle(.plain)

            HStack(spacing: 4) {
                Text("Pas encore de compte ?")
                    .foregroundStyle(AppPalette.Neutral.textTertiary)

                Button {
                    navigationPath.append(AuthFlowRoute.register)
                } label: {
                    Text("Créer un compte")
                        .fontWeight(.semibold)
                        .foregroundStyle(AppPalette.Primary.main)
                }
                .buttonStyle(.plain)
            }
            .font(.subheadline)
        }
    }
}

#Preview {
    Login()
}
