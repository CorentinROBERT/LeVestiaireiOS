//
//  RegisterView.swift
//  LeVestaire
//
//  Created by Corentin Robert on 14/06/2026.
//

import SwiftUI

struct RegisterView: View {
    @StateObject private var viewModel = RegisterViewModel()
    @State private var presentedLegalDocument: LegalDocument?

    private var birthDateRange: ClosedRange<Date> {
        let minimum = Calendar.current.date(byAdding: .year, value: -100, to: Date()) ?? Date()
        return minimum...Date()
    }

    var body: some View {
        ZStack {
            AuthScreenBackground()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 24) {
                    header
                    formCard
                    legalSection
                    submitButton
                }
                .padding(.horizontal, 24)
                .padding(.top, 16)
                .padding(.bottom, 40)
            }
            .scrollDismissesKeyboard(.interactively)
        }
        .navigationTitle(L10n.createAccount)
        .navigationBarTitleDisplayMode(.inline)
        .navigationDestination(isPresented: $viewModel.showEmailVerification) {
            EmailVerificationView(email: viewModel.trimmedEmail)
        }
        .alert(
            L10n.register,
            isPresented: Binding(
                get: { viewModel.validationMessage != nil },
                set: { if !$0 { viewModel.validationMessage = nil } }
            )
        ) {
            Button(L10n.ok, role: .cancel) {}
        } message: {
            Text(viewModel.validationMessage ?? "")
        }
        .sheet(item: $presentedLegalDocument) { document in
            LegalDocumentSheet(document: document, language: viewModel.selectedLanguage)
        }
        .onChange(of: viewModel.selectedLanguage) { _, language in
            LocalizationManager.shared.setLanguage(language)
        }
    }

    private var header: some View {
        VStack(spacing: 8) {
            UText(text: L10n.registerHeroTitle, type: .title)
                .foregroundColor(AppPalette.Primary.dark)

            UText(
                text: L10n.registerHeroSubtitle,
                type: .description
            )
            .foregroundColor(AppPalette.Neutral.textSecondary)
            .multilineTextAlignment(.center)
        }
    }

    private var formCard: some View {
        VStack(spacing: 16) {
            UGlassTextField(
                placeholder: L10n.lastNameHint,
                icon: "person.fill",
                text: $viewModel.lastName,
                style: .light,
                textContentType: .familyName,
                autocapitalization: .words
            )

            UGlassTextField(
                placeholder: L10n.firstNameHint,
                icon: "person.fill",
                text: $viewModel.firstName,
                style: .light,
                textContentType: .givenName,
                autocapitalization: .words
            )

            UGlassTextField(
                placeholder: L10n.emailAddress,
                icon: "envelope.fill",
                text: $viewModel.email,
                style: .light,
                keyboardType: .emailAddress,
                textContentType: .emailAddress
            )

            UGlassTextField(
                placeholder: L10n.password,
                icon: "lock.fill",
                text: $viewModel.password,
                style: .light,
                isSecure: true,
                isPasswordVisible: $viewModel.isPasswordVisible,
                textContentType: .newPassword
            )

            UGlassTextField(
                placeholder: L10n.confirmPassword,
                icon: "lock.rotation",
                text: $viewModel.confirmPassword,
                style: .light,
                isSecure: true,
                isPasswordVisible: $viewModel.isConfirmPasswordVisible,
                textContentType: .newPassword
            )

            UGlassFormRow(icon: "calendar") {
                VStack(alignment: .leading, spacing: 6) {
                    Text(L10n.birthdate)
                        .font(.caption)
                        .foregroundStyle(AppPalette.Neutral.textSecondary)

                    DatePicker(
                        L10n.birthdate,
                        selection: $viewModel.birthDate,
                        in: birthDateRange,
                        displayedComponents: .date
                    )
                    .labelsHidden()
                    .datePickerStyle(.compact)
                    .environment(\.locale, viewModel.selectedLanguage.locale)
                    .id(viewModel.selectedLanguage)
                    .foregroundStyle(AppPalette.Neutral.textPrimary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }

            UGlassFormRow(icon: "globe") {
                VStack(alignment: .leading, spacing: 6) {
                    Text(L10n.languageLabel)
                        .font(.caption)
                        .foregroundStyle(AppPalette.Neutral.textSecondary)

                    Picker(L10n.languageLabel, selection: $viewModel.selectedLanguage) {
                        ForEach(AppLanguage.allCases) { language in
                            Text(language.displayName).tag(language)
                        }
                    }
                    .labelsHidden()
                    .pickerStyle(.menu)
                    .foregroundStyle(AppPalette.Neutral.textPrimary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .padding(22)
        .glassEffect(.regular, in: .rect(cornerRadius: 28))
    }

    private var legalSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Toggle(isOn: $viewModel.hasAcceptedLegalTerms) {
                Text(L10n.acceptLegalDocuments)
                    .font(.subheadline)
                    .foregroundStyle(AppPalette.Neutral.textPrimary)
            }
            .tint(AppPalette.Primary.main)

            Text(L10n.legalConsentHint)
                .font(.caption)
                .foregroundStyle(AppPalette.Neutral.textTertiary)

            VStack(alignment: .leading, spacing: 10) {
                ForEach(LegalDocument.allCases) { document in
                    Button {
                        presentedLegalDocument = document
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: "doc.text")
                                .foregroundStyle(AppPalette.Primary.main)
                            Text(document.title)
                                .foregroundStyle(AppPalette.Primary.main)
                                .underline()
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(AppPalette.Primary.muted)
                        }
                        .font(.subheadline)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(20)
        .glassEffect(.regular, in: .rect(cornerRadius: 20))
    }

    private var submitButton: some View {
        UButton(
            text: viewModel.isLoading ? L10n.registerCreatingAccount : L10n.createAccountButton,
            textColor: AppPalette.Primary.onMain,
            backgroundColor: AppPalette.Primary.main,
            cornerRadius: 25,
            isFullWidth: true,
            trailingIcon: "checkmark",
            onPress: viewModel.createAccount
        )
        .opacity(viewModel.canSubmit ? 1 : 0.5)
        .disabled(!viewModel.canSubmit)
    }
}

#Preview {
    NavigationStack {
        RegisterView()
    }
}
