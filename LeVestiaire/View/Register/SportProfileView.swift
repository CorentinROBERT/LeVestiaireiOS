//
//  SportProfileView.swift
//  LeVestaire
//
//  Created by Corentin Robert on 14/06/2026.
//

import SwiftUI

struct SportProfileView: View {
    @StateObject private var viewModel: SportProfileViewModel
    @FocusState private var focusedField: Int?

    private enum Field {
        static let jersey = 1
    }

    init(mode: SportProfileMode = .onboarding, onProfileSaved: (() -> Void)? = nil) {
        _viewModel = StateObject(
            wrappedValue: SportProfileViewModel(mode: mode, onProfileSaved: onProfileSaved)
        )
    }

    var body: some View {
        ZStack {
            AuthScreenBackground()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 24) {
                    header
                    formCard
                    if !viewModel.isEditMode {
                        infoCard
                    }
                    submitButton
                }
                .padding(.horizontal, 24)
                .padding(.top, 16)
                .padding(.bottom, 40)
            }
            .scrollDismissesKeyboard(.interactively)
        }
        .onReceive(Foundation.NotificationCenter.default.publisher(for: UIResponder.keyboardWillHideNotification)) { _ in
            focusedField = nil
        }
        .safeAreaInset(edge: .bottom, spacing: 12) {
            if focusedField == Field.jersey {
                HStack {
                    Spacer()
                    Button(L10n.done) {
                        focusedField = nil
                    }
                    .fontWeight(.semibold)
                    .foregroundStyle(AppPalette.Primary.main)
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 14)
                .glassEffect(.regular, in: .rect(cornerRadius: 20))
                .padding(.horizontal, 16)
            }
        }
        .navigationTitle(viewModel.isEditMode ? L10n.editSportifProfile : L10n.sportProfileTitle)
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await viewModel.loadExistingProfileIfNeeded()
        }
        .alert(
            L10n.sportProfileTitle,
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
        VStack(spacing: 8) {
            UText(
                text: viewModel.isEditMode ? L10n.editSportifProfile : L10n.completeYourProfile,
                type: .title
            )
            .foregroundColor(AppPalette.Primary.dark)

            if !viewModel.isEditMode {
                UText(
                    text: L10n.sportProfileSubtitle,
                    type: .description
                )
                .foregroundColor(AppPalette.Neutral.textSecondary)
                .multilineTextAlignment(.center)
            }
        }
    }

    private var formCard: some View {
        VStack(spacing: 20) {
            ProfilePhotoPicker(
                selectedImage: $viewModel.profileImage,
                remoteImageURL: viewModel.uploadedProfileImageUrl,
                isUploading: viewModel.isUploadingPhoto
            )
            .onChange(of: viewModel.profileImage) { _, newImage in
                viewModel.handleProfileImageChange(to: newImage)
            }

            sectionTitle(L10n.sportInformationSection)

            UGlassFormRow(icon: "figure.run") {
                USegmentedPicker(title: L10n.strongFoot, selection: $viewModel.strongFoot) {
                    ForEach(StrongFoot.allCases) { foot in
                        Text(foot.displayName).tag(foot)
                    }
                }
            }

            UGlassTextField(
                placeholder: L10n.jerseyNumberPlaceholder,
                icon: "number",
                text: Binding(
                    get: { viewModel.jerseyNumberText },
                    set: { viewModel.updateJerseyNumber($0) }
                ),
                style: .light,
                keyboardType: .numberPad,
                focusTag: Field.jersey,
                focusedTag: $focusedField,
                usesSystemKeyboardToolbar: false,
                accessibilityIdentifier: AccessibilityID.SportProfile.jerseyField
            )

            UGlassFormRow(icon: "trophy.fill") {
                UMenuPicker(
                    title: L10n.favoriteLeague,
                    selection: $viewModel.selectedLeague,
                    labelStyle: .stacked,
                    selectionLabel: { $0.displayName },
                    onChange: { viewModel.onLeagueChanged() }
                ) {
                    ForEach(FootballLeague.allCases) { league in
                        Text(league.displayName).tag(league)
                    }
                }
            }

            UGlassFormRow(icon: "shield.fill") {
                UMenuPicker(
                    title: L10n.favoriteTeam,
                    selection: $viewModel.selectedTeam,
                    labelStyle: .stacked,
                    selectionLabel: { $0 }
                ) {
                    ForEach(viewModel.availableTeams, id: \.self) { team in
                        Text(team).tag(team)
                    }
                }
            }

            VStack(alignment: .leading, spacing: 12) {
                sectionTitle(L10n.favoritePositionsSection)

                UMultiSelectChips(
                    items: PlayerPosition.allCases,
                    selection: $viewModel.selectedPositions,
                    titleForItem: { $0.displayName }
                )
            }

            VStack(alignment: .leading, spacing: 12) {
                sectionTitle(L10n.experienceYearsSection)

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
                sectionTitle(L10n.availabilitySection)

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

            Text(L10n.profileEditableLater)
                .font(.subheadline)
                .foregroundStyle(AppPalette.Neutral.textSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(18)
        .glassEffect(.regular, in: .rect(cornerRadius: 20))
    }

    private var submitButton: some View {
        UButton(
            text: viewModel.submitButtonTitle,
            textColor: AppPalette.Primary.onMain,
            backgroundColor: AppPalette.Primary.main,
            cornerRadius: 25,
            isFullWidth: true,
            trailingIcon: "checkmark.seal.fill",
            accessibilityIdentifier: AccessibilityID.SportProfile.submitButton,
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
