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
        .navigationTitle("Créer un compte")
        .navigationBarTitleDisplayMode(.inline)
        .navigationDestination(isPresented: $viewModel.showEmailVerification) {
            EmailVerificationView(email: viewModel.email.trimmingCharacters(in: .whitespaces))
        }
        .alert(
            "Inscription",
            isPresented: Binding(
                get: { viewModel.validationMessage != nil },
                set: { if !$0 { viewModel.validationMessage = nil } }
            )
        ) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(viewModel.validationMessage ?? "")
        }
        .sheet(item: $presentedLegalDocument) { document in
            LegalDocumentSheet(document: document, language: viewModel.selectedLanguage)
        }
    }

    private var header: some View {
        VStack(spacing: 8) {
            UText(text: "Rejoignez Le Vestiaire", type: .title)
                .foregroundColor(AppPalette.Primary.dark)

            UText(
                text: "Créez votre compte pour gérer vos équipes",
                type: .description
            )
            .foregroundColor(AppPalette.Neutral.textSecondary)
            .multilineTextAlignment(.center)
        }
    }

    private var formCard: some View {
        VStack(spacing: 16) {
            UGlassTextField(
                placeholder: "Nom",
                icon: "person.fill",
                text: $viewModel.lastName,
                style: .light,
                textContentType: .familyName,
                autocapitalization: .words
            )

            UGlassTextField(
                placeholder: "Prénom",
                icon: "person.fill",
                text: $viewModel.firstName,
                style: .light,
                textContentType: .givenName,
                autocapitalization: .words
            )

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
                textContentType: .newPassword
            )

            UGlassTextField(
                placeholder: "Confirmer le mot de passe",
                icon: "lock.rotation",
                text: $viewModel.confirmPassword,
                style: .light,
                isSecure: true,
                isPasswordVisible: $viewModel.isConfirmPasswordVisible,
                textContentType: .newPassword
            )

            UGlassFormRow(icon: "calendar") {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Date de naissance")
                        .font(.caption)
                        .foregroundStyle(AppPalette.Neutral.textSecondary)

                    DatePicker(
                        "Date de naissance",
                        selection: $viewModel.birthDate,
                        in: birthDateRange,
                        displayedComponents: .date
                    )
                    .labelsHidden()
                    .datePickerStyle(.compact)
                    .foregroundStyle(AppPalette.Neutral.textPrimary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }

            UGlassFormRow(icon: "globe") {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Langue")
                        .font(.caption)
                        .foregroundStyle(AppPalette.Neutral.textSecondary)

                    Picker("Langue", selection: $viewModel.selectedLanguage) {
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
                Text("J'accepte les documents légaux suivants")
                    .font(.subheadline)
                    .foregroundStyle(AppPalette.Neutral.textPrimary)
            }
            .tint(AppPalette.Primary.main)

            Text("La switch confirme votre consentement. Consultez chaque document avant de valider.")
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
            text: "Créer mon compte",
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
