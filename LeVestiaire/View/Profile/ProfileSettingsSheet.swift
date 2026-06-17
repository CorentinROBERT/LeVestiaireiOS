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

    @State private var selectedLanguage: AppLanguage
    @State private var biometricToggleValue = false
    @State private var showsBiometricError = false

    init() {
        _selectedLanguage = State(initialValue: LocalizationManager.shared.language)
        _biometricToggleValue = State(initialValue: BiometricAuthStore.shared.isEnabled)
    }

    var body: some View {
        NavigationStack {
            ZStack {
                AuthScreenBackground()
                    .ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 20) {
                        languageCard
                        biometricCard
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 16)
                }
            }
            .navigationTitle(L10n.settings)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(L10n.close) {
                        dismiss()
                    }
                }
            }
        }
        .onChange(of: selectedLanguage) { _, language in
            localizationManager.setLanguage(language)
        }
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

    private func handleBiometricToggleChange(_ isOn: Bool) {
        if isOn {
            guard !biometricStore.isVerifying else { return }

            Task {
                let success = await biometricStore.enableWithVerification()
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
            Picker(L10n.appLanguage, selection: $selectedLanguage) {
                ForEach(AppLanguage.allCases) { language in
                    Text(language.displayName).tag(language)
                }
            }
            .pickerStyle(.menu)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
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

#Preview {
    ProfileSettingsSheet()
}
