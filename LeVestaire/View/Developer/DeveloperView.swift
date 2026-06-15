//
//  DeveloperView.swift
//  LeVestaire
//
//  Created by Corentin Robert on 12/06/2026.
//

import SwiftUI

struct DeveloperView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel = DeveloperViewModel()

    var body: some View {
        NavigationStack {
            ZStack {
                LinearGradient(
                    colors: [
                        AppPalette.Neutral.background,
                        AppPalette.Neutral.backgroundMid,
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        apiEnvironmentCard

                        developerCard(
                            title: "Informations",
                            icon: "hammer.fill",
                            tint: AppPalette.Primary.main
                        ) {
                            infoRow(label: "Version", value: viewModel.appVersion)
                            infoRow(label: "Numéro de build", value: viewModel.appBuildNumber)
                            infoRow(label: "Plateforme", value: "iOS")
                        }
                    }
                    .padding(24)
                }
            }
            .navigationTitle("Développeur")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Fermer") {
                        dismiss()
                    }
                    .foregroundStyle(AppPalette.Primary.main)
                }
            }
        }
    }

    private var apiEnvironmentCard: some View {
        developerCard(
            title: "Environnement API",
            icon: "network",
            tint: AppPalette.Secondary.mint
        ) {
            VStack(alignment: .leading, spacing: 16) {
                Picker("Environnement", selection: $viewModel.selectedEnvironment) {
                    ForEach(APIEnvironment.allCases) { environment in
                        Text(environment.displayName).tag(environment)
                    }
                }
                .pickerStyle(.segmented)

                if viewModel.isCustomEnvironment {
                    UGlassTextField(
                        placeholder: "https://mon-api.local",
                        icon: "link",
                        text: $viewModel.customBaseURL,
                        style: .light,
                        keyboardType: .URL,
                        textContentType: .URL
                    )
                }

                infoRow(label: "URL testée", value: viewModel.healthCheckURL ?? "—")

                UButton(
                    text: viewModel.apiTestState == .loading ? "Test en cours..." : "Tester l'URL",
                    textColor: AppPalette.Primary.onMain,
                    backgroundColor: AppPalette.Primary.main,
                    cornerRadius: 25,
                    isFullWidth: true,
                    leadingIcon: viewModel.apiTestState == .loading ? nil : "bolt.fill",
                    onPress: viewModel.testAPI
                )
                .disabled(!viewModel.canTestAPI)
                .opacity(viewModel.canTestAPI ? 1 : 0.5)

                apiTestResultView
            }
        }
    }

    @ViewBuilder
    private var apiTestResultView: some View {
        switch viewModel.apiTestState {
        case .idle:
            EmptyView()
        case .loading:
            HStack(spacing: 10) {
                ProgressView()
                Text("Connexion à l'API...")
                    .font(.subheadline)
                    .foregroundStyle(AppPalette.Neutral.textSecondary)
            }
        case .success(let statusCode, let durationMs):
            HStack(alignment: .top, spacing: 10) {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(AppPalette.Semantic.success)
                Text("Serveur joignable — HTTP \(statusCode) (\(durationMs) ms)")
                    .font(.subheadline)
                    .foregroundStyle(AppPalette.Neutral.textPrimary)
            }
        case .failure(let message):
            HStack(alignment: .top, spacing: 10) {
                Image(systemName: "xmark.circle.fill")
                    .foregroundStyle(AppPalette.Semantic.error)
                Text(message)
                    .font(.subheadline)
                    .foregroundStyle(AppPalette.Neutral.textPrimary)
            }
        }
    }

    private func developerCard<Content: View>(
        title: String,
        icon: String,
        tint: Color,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 10) {
                Image(systemName: icon)
                    .foregroundStyle(tint)
                Text(title)
                    .font(.headline)
                    .foregroundStyle(AppPalette.Primary.dark)
            }

            content()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(20)
        .glassEffect(.regular, in: .rect(cornerRadius: 20))
    }

    private func infoRow(label: String, value: String) -> some View {
        HStack(alignment: .top) {
            Text(label)
                .foregroundStyle(AppPalette.Neutral.textTertiary)
            Spacer()
            Text(value.isEmpty ? "—" : value)
                .fontWeight(.medium)
                .foregroundStyle(AppPalette.Neutral.textPrimary)
                .multilineTextAlignment(.trailing)
        }
        .font(.subheadline)
    }
}

#Preview {
    DeveloperView()
}
