//
//  SportProfileView.swift
//  LeVestaire
//
//  Created by Corentin Robert on 14/06/2026.
//

import SwiftUI

struct SportProfileView: View {
    @StateObject private var viewModel = SportProfileViewModel()

    var body: some View {
        ZStack {
            AuthScreenBackground()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 24) {
                    header
                    formCard
                    infoCard
                    submitButton
                }
                .padding(.horizontal, 24)
                .padding(.top, 16)
                .padding(.bottom, 40)
            }
        }
        .navigationTitle("Profil sportif")
        .navigationBarTitleDisplayMode(.inline)
        .alert(
            "Profil sportif",
            isPresented: Binding(
                get: { viewModel.validationMessage != nil },
                set: { if !$0 { viewModel.validationMessage = nil } }
            )
        ) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(viewModel.validationMessage ?? "")
        }
    }

    private var header: some View {
        VStack(spacing: 8) {
            UText(text: "Complétez votre profil", type: .title)
                .foregroundColor(AppPalette.Primary.dark)

            UText(
                text: "Personnalisez votre expérience sur Le Vestiaire",
                type: .description
            )
            .foregroundColor(AppPalette.Neutral.textSecondary)
            .multilineTextAlignment(.center)
        }
    }

    private var formCard: some View {
        VStack(spacing: 20) {
            ProfilePhotoPicker(selectedImage: $viewModel.profileImage)

            sectionTitle("Informations sportives")

            UGlassFormRow(icon: "figure.run") {
                Picker("Pied fort", selection: $viewModel.strongFoot) {
                    ForEach(StrongFoot.allCases) { foot in
                        Text(foot.displayName).tag(foot)
                    }
                }
                .pickerStyle(.segmented)
            }

            UGlassTextField(
                placeholder: "Numéro de maillot (0-999)",
                icon: "number",
                text: Binding(
                    get: { viewModel.jerseyNumberText },
                    set: { viewModel.updateJerseyNumber($0) }
                ),
                style: .light,
                keyboardType: .numberPad
            )

            UGlassFormRow(icon: "trophy.fill") {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Championnat préféré")
                        .font(.caption)
                        .foregroundStyle(AppPalette.Neutral.textSecondary)

                    Picker("Championnat préféré", selection: $viewModel.selectedLeague) {
                        ForEach(FootballLeague.allCases) { league in
                            Text(league.displayName).tag(league)
                        }
                    }
                    .labelsHidden()
                    .pickerStyle(.menu)
                    .foregroundStyle(AppPalette.Neutral.textPrimary)
                    .onChange(of: viewModel.selectedLeague) { _, _ in
                        viewModel.onLeagueChanged()
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }

            UGlassFormRow(icon: "shield.fill") {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Équipe préférée")
                        .font(.caption)
                        .foregroundStyle(AppPalette.Neutral.textSecondary)

                    Picker("Équipe préférée", selection: $viewModel.selectedTeam) {
                        ForEach(viewModel.availableTeams, id: \.self) { team in
                            Text(team).tag(team)
                        }
                    }
                    .labelsHidden()
                    .pickerStyle(.menu)
                    .foregroundStyle(AppPalette.Neutral.textPrimary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }

            VStack(alignment: .leading, spacing: 12) {
                sectionTitle("Postes favoris")

                UMultiSelectChips(
                    items: PlayerPosition.allCases,
                    selection: $viewModel.selectedPositions,
                    titleForItem: { $0.displayName }
                )
            }

            VStack(alignment: .leading, spacing: 12) {
                sectionTitle("Années d'expérience")

                Text(viewModel.experienceLevel.displayName)
                    .font(.headline)
                    .foregroundStyle(AppPalette.Primary.main)

                Slider(
                    value: Binding(
                        get: { Double(viewModel.experienceLevel.rawValue) },
                        set: { newValue in
                            viewModel.experienceLevel = ExperienceLevel(rawValue: Int(newValue.rounded())) ?? .beginner
                        }
                    ),
                    in: 0...3,
                    step: 1
                )
                .tint(AppPalette.Primary.main)

                HStack {
                    ForEach(ExperienceLevel.allCases) { level in
                        Text(level.displayName)
                            .font(.caption2)
                            .foregroundStyle(AppPalette.Neutral.textTertiary)
                            .frame(maxWidth: .infinity)
                    }
                }
            }

            VStack(alignment: .leading, spacing: 12) {
                sectionTitle("Disponibilité")

                UMultiSelectChips(
                    items: Weekday.allCases,
                    selection: $viewModel.selectedWeekdays,
                    titleForItem: { $0.displayName }
                )
            }
        }
        .padding(22)
        .glassEffect(.regular, in: .rect(cornerRadius: 28))
    }

    private var infoCard: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: "info.circle.fill")
                .foregroundStyle(AppPalette.Primary.main)

            Text("Vous pouvez modifier ces informations dans votre profil.")
                .font(.subheadline)
                .foregroundStyle(AppPalette.Neutral.textSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(18)
        .glassEffect(.regular, in: .rect(cornerRadius: 20))
    }

    private var submitButton: some View {
        UButton(
            text: "Finaliser mon profil",
            textColor: AppPalette.Primary.onMain,
            backgroundColor: AppPalette.Primary.main,
            cornerRadius: 25,
            isFullWidth: true,
            trailingIcon: "checkmark.seal.fill",
            onPress: viewModel.finalizeProfile
        )
        .opacity(viewModel.canSubmit ? 1 : 0.5)
        .disabled(!viewModel.canSubmit)
    }

    private func sectionTitle(_ title: String) -> some View {
        Text(title)
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(AppPalette.Primary.dark)
            .frame(maxWidth: .infinity, alignment: .leading)
    }
}

#Preview {
    NavigationStack {
        SportProfileView()
    }
}
