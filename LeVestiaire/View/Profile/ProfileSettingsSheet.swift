//
//  ProfileSettingsSheet.swift
//  LeVestaire
//
//  Created by Corentin Robert on 16/06/2026.
//

import SwiftUI

struct ProfileSettingsSheet: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var localizationManager = LocalizationManager.shared
    @ObservedObject private var biometricStore = BiometricAuthStore.shared

    @State private var biometricToggleValue = false
    @State private var showsBiometricError = false
    @State private var sheetHeight: CGFloat = 360

    init() {
        _biometricToggleValue = State(initialValue: BiometricAuthStore.shared.isEnabled)
    }

    var body: some View {
        VStack(spacing: 0) {
            sheetHeader

            VStack(spacing: 20) {
                languageCard
                biometricCard
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 20)
        }
        .padding(.top, 8)
        .background {
            ZStack {
                AuthScreenBackground()

                GeometryReader { geometry in
                    Color.clear.preference(
                        key: SheetContentHeightPreferenceKey.self,
                        value: geometry.size.height
                    )
                }
            }
        }
        .environment(\.locale, localizationManager.locale)
        .onPreferenceChange(SheetContentHeightPreferenceKey.self) { height in
            guard height > 0 else { return }
            sheetHeight = height
        }
        .presentationDetents([.height(sheetHeight)])
        .presentationDragIndicator(.visible)
        .onChange(of: biometricToggleValue) { _, isOn in
            handleBiometricToggleChange(isOn)
        }
        .alert(L10n.biometricLogin, isPresented: $showsBiometricError) {
            Button(L10n.ok, role: .cancel) {
                biometricStore.lastErrorMessage = nil
            }
        } message: {
            Text(biometricStore.lastErrorMessage ?? L10n.biometricAuthenticationFailed)
        }
    }

    private var sheetHeader: some View {
        HStack(alignment: .center) {
            Text(L10n.settings)
                .font(.headline)
                .foregroundStyle(AppPalette.Neutral.textPrimary)

            Spacer()

            Button(L10n.close) {
                dismiss()
            }
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(AppPalette.Primary.main)
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .glassEffect(.regular, in: .rect(cornerRadius: 20))
            .buttonStyle(.fullTap)
        }
        .padding(.horizontal, 20)
        .padding(.top, 28)
        .padding(.bottom, 12)
    }

    private func handleBiometricToggleChange(_ isOn: Bool) {
        if isOn {
            guard !biometricStore.isVerifying else { return }

            Task {
                let success = await biometricStore.enableWithVerification(
                    refreshToken: AuthService.shared.refreshToken
                )
                if !success {
                    biometricToggleValue = false
                    showsBiometricError = true
                }
            }
        } else {
            biometricStore.disable()
        }
    }

    private var languageCard: some View {
        UCard(title: L10n.appLanguage, icon: "globe") {
            USegmentedPicker(
                selection: languageBinding,
                accessibilityValue: localizationManager.language.displayName
            ) {
                ForEach(AppLanguage.allCases) { language in
                    Text(language.displayName).tag(language)
                }
            }
        }
    }

    private var languageBinding: Binding<AppLanguage> {
        Binding(
            get: { localizationManager.language },
            set: { localizationManager.setLanguage($0) }
        )
    }

    private var biometricCard: some View {
        UCard(title: L10n.biometricLogin, icon: "faceid") {
            if biometricStore.isAvailable {
                Toggle(isOn: $biometricToggleValue) {
                    VStack(alignment: .leading, spacing: 4) {
                        HStack(spacing: 8) {
                            Text(biometricStore.biometryLabel)
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(AppPalette.Neutral.textPrimary)

                            if biometricStore.isVerifying {
                                ProgressView()
                                    .controlSize(.small)
                            }
                        }

                        Text(L10n.biometricLoginDescription)
                            .font(.caption)
                            .foregroundStyle(AppPalette.Neutral.textSecondary)
                    }
                }
                .tint(AppPalette.Primary.main)
                .disabled(biometricStore.isVerifying)
            } else {
                Text(L10n.biometricUnavailable)
                    .font(.subheadline)
                    .foregroundStyle(AppPalette.Neutral.textSecondary)
            }
        }
    }
}

private struct SheetContentHeightPreferenceKey: PreferenceKey {
    static var defaultValue: CGFloat = 0

    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = max(value, nextValue())
    }
}

#Preview {
    ProfileSettingsSheet()
}
