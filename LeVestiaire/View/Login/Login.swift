//
//  Login.swift
//  LeVestaire
//
//  Created by Corentin Robert on 12/06/2026.
//

import SwiftUI

struct Login: View {
    @EnvironmentObject private var teamInviteCoordinator: TeamInviteCoordinator
    @StateObject private var viewModel = LoginViewModel()
    @StateObject private var developerAccess = DeveloperAccessViewModel()
    @State private var navigationPath = NavigationPath()
    @FocusState private var focusedField: Int?

    var body: some View {
        NavigationStack(path: $navigationPath) {
            loginContent
                .navigationDestination(for: AuthFlowRoute.self) { route in
                    switch route {
                    case .register:
                        RegisterView { email in
                            navigationPath.append(AuthFlowRoute.emailVerification(email: email))
                        }
                    case .emailVerification(let email):
                        EmailVerificationView(email: email)
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
        .onAppear {
            openResetPasswordForUITestingIfNeeded()
        }
    }

    private func openResetPasswordForUITestingIfNeeded() {
        guard UITestLaunchArgument.shouldOpenResetPassword else { return }
        DispatchQueue.main.async {
            guard navigationPath.isEmpty else { return }
            navigationPath.append(AuthFlowRoute.resetPassword(token: nil))
        }
    }

    private var loginContent: some View {
        ZStack {
            AuthScreenBackground()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 28) {
                    header

                    if let teamName = teamInviteCoordinator.pendingInviteTeamName {
                        TeamInviteBanner(teamName: teamName)
                    }

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
        .developerAccess(developerAccess)
        .navigationDestination(isPresented: $viewModel.showEmailVerification) {
            EmailVerificationView(email: viewModel.trimmedEmail)
        }
        .alert(
            L10n.login,
            isPresented: Binding(
                get: { viewModel.validationMessage != nil },
                set: { if !$0 { viewModel.validationMessage = nil } }
            )
        ) {
            Button(L10n.ok, role: .cancel) {}
        } message: {
            Text(viewModel.validationMessage ?? "")
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
                    developerAccess.registerTap()
                }

            UText(text: L10n.loginHeroTitle, type: .title)
                .foregroundColor(AppPalette.Primary.dark)

            UText(
                text: L10n.loginHeroSubtitle,
                type: .description
            )
            .foregroundColor(AppPalette.Neutral.textSecondary)
            .multilineTextAlignment(.center)
        }
    }

    private var formCard: some View {
        VStack(spacing: 18) {
            UGlassTextField(
                placeholder: L10n.emailAddress,
                icon: "envelope.fill",
                text: $viewModel.email,
                style: .light,
                keyboardType: .emailAddress,
                textContentType: viewModel.requiresPasswordReauthentication ? nil : .emailAddress,
                usesOneTimeCodeAutofill: viewModel.requiresPasswordReauthentication,
                submitLabel: .next,
                focusTag: 1,
                focusedTag: $focusedField,
                nextFocusTag: 2,
                accessibilityIdentifier: AccessibilityID.Auth.emailField
            )

            UGlassTextField(
                placeholder: L10n.password,
                icon: "lock.fill",
                text: $viewModel.password,
                style: .light,
                isSecure: true,
                isPasswordVisible: $viewModel.isPasswordVisible,
                textContentType: viewModel.requiresPasswordReauthentication ? nil : .password,
                usesOneTimeCodeAutofill: viewModel.requiresPasswordReauthentication,
                submitLabel: .go,
                onSubmit: viewModel.login,
                focusTag: 2,
                focusedTag: $focusedField,
                accessibilityIdentifier: AccessibilityID.Auth.passwordField
            )

            UButton(
                text: viewModel.isLoading ? L10n.loginInProgress : L10n.loginButton,
                textColor: AppPalette.Primary.onMain,
                backgroundColor: AppPalette.Primary.main,
                cornerRadius: 25,
                isFullWidth: true,
                trailingIcon: "arrow.right",
                accessibilityIdentifier: AccessibilityID.Auth.loginButton,
                onPress: viewModel.login
            )
            .opacity(viewModel.isLoading ? 0.7 : 1)
            .disabled(viewModel.isLoading)
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
                Text(L10n.forgotPasswordQuestion)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(AppPalette.Primary.main)
            }
            .buttonStyle(.fullTap)
            .accessibilityIdentifier(AccessibilityID.Auth.forgotPasswordLink)

            HStack(spacing: 4) {
                Text(L10n.noAccountYet)
                    .foregroundStyle(AppPalette.Neutral.textTertiary)

                Button {
                    navigationPath.append(AuthFlowRoute.register)
                } label: {
                    Text(L10n.createAccount)
                        .fontWeight(.semibold)
                        .foregroundStyle(AppPalette.Primary.main)
                }
                .buttonStyle(.fullTap)
                .accessibilityIdentifier(AccessibilityID.Auth.createAccountLink)
            }
            .font(.subheadline)
        }
    }
}

#Preview {
    Login()
        .environmentObject(AuthService.shared)
        .environmentObject(TeamInviteCoordinator.shared)
}
