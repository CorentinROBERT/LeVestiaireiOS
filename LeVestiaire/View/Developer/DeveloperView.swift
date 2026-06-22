//
//  DeveloperView.swift
//  LeVestaire
//
//  Created by Corentin Robert on 12/06/2026.
//

import SwiftUI
import FirebaseCrashlytics

struct DeveloperView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel = DeveloperViewModel()
    @ObservedObject private var remoteSettings = RemoteSettingsService.shared

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

                        crashlyticsCard

                        remoteSettingsCard

                        developerCard(
                            title: L10n.informationTitle,
                            icon: "hammer.fill",
                            tint: AppPalette.Primary.main
                        ) {
                            infoRow(label: L10n.versionLabel, value: viewModel.appVersion)
                            infoRow(label: L10n.buildNumberLabel, value: viewModel.appBuildNumber)
                            infoRow(label: L10n.platformLabel, value: "iOS")
                        }
                    }
                    .padding(24)
                }
            }
            .navigationTitle(L10n.developerViewTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(L10n.close) {
                        dismiss()
                    }
                    .foregroundStyle(AppPalette.Primary.main)
                }
            }
        }
    }

    private var apiEnvironmentCard: some View {
        developerCard(
            title: L10n.apiEnvironment,
            icon: "network",
            tint: AppPalette.Secondary.mint
        ) {
            VStack(alignment: .leading, spacing: 16) {
                Picker(L10n.environment, selection: $viewModel.selectedEnvironment) {
                    ForEach(APIEnvironment.allCases) { environment in
                        Text(environment.displayName).tag(environment)
                    }
                }
                .pickerStyle(.segmented)

                if viewModel.isCustomEnvironment {
                    UGlassTextField(
                        placeholder: L10n.customApiUrlPlaceholder,
                        icon: "link",
                        text: $viewModel.customBaseURL,
                        style: .light,
                        keyboardType: .URL,
                        textContentType: .URL
                    )
                }

                infoRow(label: L10n.testedUrlLabel, value: viewModel.healthCheckURL ?? "—")

                UButton(
                    text: viewModel.apiTestState == .loading ? L10n.testUrlInProgress : L10n.testUrlButton,
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

    private var crashlyticsCard: some View {
        developerCard(
            title: L10n.developerCrashlyticsTitle,
            icon: "flame.fill",
            tint: AppPalette.Semantic.error
        ) {
            VStack(alignment: .leading, spacing: 16) {
                Text(L10n.developerCrashlyticsHint)
                    .font(.subheadline)
                    .foregroundStyle(AppPalette.Neutral.textSecondary)

                UButton(
                    text: L10n.developerTestCrashButton,
                    textColor: AppPalette.Primary.onMain,
                    backgroundColor: AppPalette.Semantic.error,
                    cornerRadius: 25,
                    isFullWidth: true,
                    leadingIcon: "bolt.trianglebadge.exclamationmark.fill",
                    onPress: triggerTestCrash
                )
            }
        }
    }

    private var remoteSettingsCard: some View {
        developerCard(
            title: L10n.developerRemoteSettingsTitle,
            icon: "gearshape.2.fill",
            tint: AppPalette.Primary.main
        ) {
            VStack(alignment: .leading, spacing: 8) {
                infoRow(
                    label: L10n.developerRemoteSettingsLoaded,
                    value: remoteSettings.hasLoadedSettings ? L10n.yes : L10n.no
                )
                infoRow(label: L10n.versionLabel, value: AppInfo.version)
                infoRow(
                    label: L10n.developerRemoteSettingsMinimumVersion,
                    value: remoteSettings.settings.minimumVersion ?? "—"
                )
                infoRow(
                    label: L10n.developerRemoteSettingsForceUpdate,
                    value: remoteSettings.settings.forceUpdate?.enabled == true ? L10n.yes : L10n.no
                )
                infoRow(
                    label: L10n.developerRemoteSettingsForceUpdateRequired,
                    value: remoteSettings.requiresForceUpdate ? L10n.yes : L10n.no
                )
            }
        }
        .task {
            remoteSettings.start()
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
                Text(L10n.connectingToApi)
                    .font(.subheadline)
                    .foregroundStyle(AppPalette.Neutral.textSecondary)
            }
        case .success(let statusCode, let durationMs):
            HStack(alignment: .top, spacing: 10) {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(AppPalette.Semantic.success)
                Text(L10n.serverReachable(statusCode: statusCode, durationMs: durationMs))
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

    private func triggerTestCrash() {
        Crashlytics.crashlytics().log("Developer menu test crash")
        fatalError("Crashlytics test crash")
    }
}

#Preview {
    DeveloperView()
}
