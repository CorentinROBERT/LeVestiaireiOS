//
//  EmailVerificationView.swift
//  LeVestaire
//
//  Created by Corentin Robert on 14/06/2026.
//

import SwiftUI

struct EmailVerificationView: View {
    @StateObject private var viewModel: EmailVerificationViewModel

    init(email: String) {
        _viewModel = StateObject(wrappedValue: EmailVerificationViewModel(email: email))
    }

    var body: some View {
        ZStack {
            AuthScreenBackground()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 24) {
                    headerIcon
                    verificationCard
                    actionButtons
                    tipsCard
                }
                .padding(.horizontal, 24)
                .padding(.top, 24)
                .padding(.bottom, 40)
            }
        }
        .navigationTitle(L10n.emailVerificationNavTitle)
        .navigationBarTitleDisplayMode(.inline)
        .alert(
            L10n.emailVerificationAlertTitle,
            isPresented: Binding(
                get: { viewModel.feedbackMessage != nil },
                set: { if !$0 { viewModel.feedbackMessage = nil } }
            )
        ) {
            Button(L10n.ok, role: .cancel) {}
        } message: {
            Text(viewModel.feedbackMessage ?? "")
        }
    }

    private var headerIcon: some View {
        Image(systemName: "envelope.badge.fill")
            .font(.system(size: 40, weight: .semibold))
            .foregroundStyle(AppPalette.Primary.main)
            .frame(width: 80, height: 80)
            .glassEffect(.regular, in: .circle)
    }

    private var verificationCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(L10n.verificationEmailSentTo)
                .font(.subheadline)
                .foregroundStyle(AppPalette.Neutral.textSecondary)

            Text(viewModel.email)
                .font(.headline)
                .foregroundStyle(AppPalette.Primary.dark)
                .frame(maxWidth: .infinity, alignment: .leading)

            Text(L10n.clickLinkInEmail)
                .font(.subheadline)
                .foregroundStyle(AppPalette.Neutral.textPrimary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(22)
        .glassEffect(.regular, in: .rect(cornerRadius: 28))
    }

    private var actionButtons: some View {
        VStack(spacing: 14) {
            UButton(
                text: viewModel.isCheckingVerification ? L10n.emailVerificationChecking : L10n.iHaveVerifiedMyEmail,
                textColor: AppPalette.Primary.onMain,
                backgroundColor: AppPalette.Primary.main,
                cornerRadius: 25,
                isFullWidth: true,
                trailingIcon: "checkmark.circle",
                accessibilityIdentifier: AccessibilityID.EmailVerification.confirmButton,
                onPress: viewModel.confirmVerification
            )
            .disabled(viewModel.isCheckingVerification)

            UButton(
                text: resendButtonTitle,
                textColor: AppPalette.Primary.main,
                backgroundColor: AppPalette.Neutral.surface,
                cornerRadius: 25,
                isFullWidth: true,
                leadingIcon: "arrow.clockwise",
                onPress: viewModel.resendEmail
            )
            .opacity(viewModel.canResendEmail ? 1 : 0.5)
            .disabled(!viewModel.canResendEmail)
        }
    }

    private var resendButtonTitle: String {
        if viewModel.isResending {
            return L10n.sendingInProgress
        }
        if viewModel.resendCooldownRemaining > 0 {
            return L10n.resendEmailCooldown(viewModel.resendCooldownRemaining)
        }
        return L10n.resendEmail
    }

    private var tipsCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 8) {
                Image(systemName: "lightbulb.fill")
                    .foregroundStyle(AppPalette.Secondary.coral)
                Text(L10n.tipsTitle)
                    .font(.headline)
                    .foregroundStyle(AppPalette.Primary.dark)
            }

            VStack(alignment: .leading, spacing: 10) {
                tipRow(L10n.checkSpamFolder)
                tipRow(L10n.ensureEmailAddressCorrect)
                tipRow(L10n.waitFewMinutesBeforeResending)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(20)
        .glassEffect(.regular, in: .rect(cornerRadius: 20))
    }

    private func tipRow(_ text: String) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: "circle.fill")
                .font(.system(size: 6))
                .foregroundStyle(AppPalette.Primary.muted)
                .padding(.top, 6)

            Text(text)
                .font(.subheadline)
                .foregroundStyle(AppPalette.Neutral.textSecondary)
        }
    }
}

#Preview {
    NavigationStack {
        EmailVerificationView(email: "utilisateur@exemple.com")
    }
}
