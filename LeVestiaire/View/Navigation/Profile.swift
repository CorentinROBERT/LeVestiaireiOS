//
//  Profile.swift
//  LeVestaire
//
//  Created by Corentin Robert on 15/06/2026.
//

import SwiftUI

struct Profile: View {
    @StateObject private var viewModel = ProfileViewModel()
    @StateObject private var developerAccess = DeveloperAccessViewModel()
    @State private var isStatsExpanded = false

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 20) {
                if viewModel.isLoading, viewModel.user == nil {
                    ProgressView(L10n.loading)
                        .frame(maxWidth: .infinity)
                        .padding(.top, 40)
                } else {
                    avatarSection
                    identityCard
                    sportCard
                    statsCard
                    actionsSection
                    versionFooter
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 8)
            .padding(.bottom, 24)
        }
        .task {
            await viewModel.loadProfile()
        }
        .refreshable {
            await viewModel.refreshFromPullToRefresh()
        }
        .sheet(isPresented: $viewModel.showsSettings) {
            ProfileSettingsSheet()
        }
        .navigationDestination(isPresented: $viewModel.showsEditSportProfile) {
            SportProfileView(mode: .edit) {
                viewModel.reloadAfterSportProfileEdit()
            }
        }
        .alert(L10n.logout, isPresented: $viewModel.showsLogoutConfirmation) {
            Button(L10n.cancel, role: .cancel) {}
            Button(L10n.logout, role: .destructive) {
                viewModel.logout()
            }
        } message: {
            Text(L10n.confirmLogout)
        }
        .alert(L10n.deleteAccountConfirmTitle, isPresented: $viewModel.showsDeleteAccountConfirmation) {
            Button(L10n.cancel, role: .cancel) {}
            Button(L10n.deleteAccount, role: .destructive) {
                viewModel.requestAccountDeletion()
            }
        } message: {
            Text(L10n.deleteAccountConfirmMessage)
        }
        .alert(
            L10n.profile,
            isPresented: Binding(
                get: { viewModel.alertMessage != nil },
                set: { if !$0 { viewModel.alertMessage = nil } }
            )
        ) {
            Button(L10n.ok, role: .cancel) {}
        } message: {
            Text(viewModel.alertMessage ?? "")
        }
        .developerAccess(developerAccess)
    }

    private var avatarSection: some View {
        ProfilePhotoPicker(
            selectedImage: $viewModel.profileImage,
            remoteImageURL: viewModel.avatarURL,
            initials: viewModel.initials,
            isUploading: viewModel.isUploadingPhoto
        )
        .onChange(of: viewModel.profileImage) { _, newImage in
            viewModel.handleProfileImageChange(to: newImage)
        }
    }

    private var identityCard: some View {
        UCard(title: L10n.profile, icon: "person.fill") {
            VStack(alignment: .leading, spacing: 12) {
                profileRow(label: L10n.firstName, value: viewModel.user?.firstName ?? "—")
                profileRow(label: L10n.lastName, value: viewModel.user?.lastName ?? "—")
                profileRow(label: L10n.email, value: viewModel.user?.email ?? "—")

                if viewModel.hasPendingAccountDeletion {
                    accountDeletionBanner
                }
            }
        }
    }

    private var sportCard: some View {
        UCard(
            title: L10n.sportProfileTitle,
            icon: "sportscourt.fill",
            trailingHeader: {
                Button {
                    viewModel.showsEditSportProfile = true
                } label: {
                    Image(systemName: "square.and.pencil")
                        .font(.body.weight(.semibold))
                        .foregroundStyle(AppPalette.Primary.main)
                        .frame(width: 32, height: 32)
                        .background(
                            Circle()
                                .fill(AppPalette.Primary.soft.opacity(0.6))
                        )
                }
                .buttonStyle(.plain)
                .accessibilityLabel(L10n.editSportifProfile)
            }
        ) {
            VStack(alignment: .leading, spacing: 12) {
                profileRow(
                    label: L10n.favoriteTeam,
                    value: viewModel.sportProfile?.favoriteTeam ?? L10n.none
                )
                profileRow(
                    label: L10n.strongFoot,
                    value: viewModel.strongFootLabel(for: viewModel.sportProfile?.strongFoot)
                )
                profileRow(
                    label: L10n.jerseyNumber,
                    value: viewModel.jerseyNumberLabel(for: viewModel.sportProfile?.jerseyNumber)
                )
            }
        }
    }

    private var statsCard: some View {
        UCard {
            VStack(alignment: .leading, spacing: isStatsExpanded ? 16 : 12) {
                statsExpandableHeader

                if isStatsExpanded {
                    statsExpandedContent
                } else {
                    statsCollapsedContent
                }
            }
        }
    }

    private var statsExpandableHeader: some View {
        Button {
            withAnimation(.easeInOut(duration: 0.25)) {
                isStatsExpanded.toggle()
            }
        } label: {
            HStack(spacing: 10) {
                Image(systemName: "chart.bar.fill")
                    .foregroundStyle(AppPalette.Primary.main)

                Text(L10n.statistics)
                    .font(.headline)
                    .foregroundStyle(AppPalette.Primary.dark)

                Spacer()

                if viewModel.isLoadingStats {
                    ProgressView()
                        .controlSize(.small)
                }

                Image(systemName: "chevron.down")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(AppPalette.Neutral.textSecondary)
                    .rotationEffect(.degrees(isStatsExpanded ? -180 : 0))
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private var statsCollapsedContent: some View {
        Group {
            if let stats = viewModel.seasonStats, stats.hasAnyValue {
                HStack(spacing: 12) {
                    collapsedStatItem(label: L10n.matchesPlayed, value: stats.matchesPlayed)
                    collapsedStatItem(label: L10n.goals, value: stats.goals)
                    collapsedStatItem(label: L10n.assists, value: stats.assists)
                }
            } else if !viewModel.isLoadingStats {
                Text(L10n.noStatisticsAvailable)
                    .font(.caption)
                    .foregroundStyle(AppPalette.Neutral.textSecondary)
            }
        }
    }

    private var statsExpandedContent: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(L10n.userStatsSubtitle)
                .font(.caption)
                .foregroundStyle(AppPalette.Neutral.textSecondary)

            if !viewModel.availableSeasons.isEmpty {
                HStack {
                    Text(L10n.season)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(AppPalette.Neutral.textPrimary)

                    Spacer()

                    Picker(L10n.season, selection: $viewModel.selectedSeason) {
                        ForEach(viewModel.availableSeasons, id: \.self) { season in
                            Text(SeasonFormatter.shortLabel(for: season)).tag(season)
                        }
                    }
                    .labelsHidden()
                    .pickerStyle(.menu)
                    .onChange(of: viewModel.selectedSeason) { _, _ in
                        viewModel.onSeasonChanged()
                    }
                }
            }

            if viewModel.isLoadingStats {
                ProgressView()
                    .frame(maxWidth: .infinity)
            } else if let stats = viewModel.seasonStats, stats.hasAnyValue {
                statsGrid(stats)

                if let topConnection = stats.topConnection, !topConnection.isEmpty {
                    profileRow(label: L10n.topConnection, value: topConnection)
                }
            } else {
                Text(L10n.noStatisticsAvailable)
                    .font(.subheadline)
                    .foregroundStyle(AppPalette.Neutral.textSecondary)
            }
        }
    }

    private func collapsedStatItem(label: String, value: Int) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label)
                .font(.caption2)
                .foregroundStyle(AppPalette.Neutral.textSecondary)
                .lineLimit(1)
                .minimumScaleFactor(0.8)

            Text("\(value)")
                .font(.subheadline.weight(.bold))
                .foregroundStyle(AppPalette.Primary.main)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var actionsSection: some View {
        VStack(spacing: 12) {
            UButton(
                text: L10n.settings,
                textColor: AppPalette.Primary.main,
                backgroundColor: AppPalette.Primary.soft,
                cornerRadius: 20,
                isFullWidth: true,
                leadingIcon: "gearshape.fill",
                onPress: { viewModel.showsSettings = true }
            )

            if !viewModel.hasPendingAccountDeletion {
                UButton(
                    text: L10n.deleteAccount,
                    textColor: AppPalette.Semantic.error,
                    backgroundColor: AppPalette.Semantic.error.opacity(0.12),
                    cornerRadius: 20,
                    isFullWidth: true,
                    leadingIcon: "trash.fill",
                    onPress: { viewModel.showsDeleteAccountConfirmation = true }
                )
                .disabled(viewModel.isDeletingAccount)
            }

            UButton(
                text: viewModel.isLoggingOut ? L10n.logoutInProgress : L10n.signOutButton,
                textColor: AppPalette.Primary.onMain,
                backgroundColor: AppPalette.Primary.buttonStrong,
                cornerRadius: 20,
                isFullWidth: true,
                trailingIcon: "rectangle.portrait.and.arrow.right",
                onPress: { viewModel.showsLogoutConfirmation = true }
            )
            .disabled(viewModel.isLoggingOut)
        }
    }

    private var versionFooter: some View {
        Text(AppInfo.versionLabel)
            .font(.caption)
            .foregroundStyle(AppPalette.Neutral.textTertiary)
            .frame(maxWidth: .infinity)
            .contentShape(Rectangle())
            .onTapGesture {
                developerAccess.registerTap()
            }
    }

    private var accountDeletionBanner: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label(L10n.accountDeletionInProgress, systemImage: "exclamationmark.triangle.fill")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(AppPalette.Semantic.warning)

            Text(L10n.accountDeletionScheduled(viewModel.accountDeletionDaysRemaining))
                .font(.caption)
                .foregroundStyle(AppPalette.Neutral.textSecondary)

            if viewModel.canCancelAccountDeletion {
                Button {
                    viewModel.cancelAccountDeletion()
                } label: {
                    Text(
                        viewModel.isCancellingDeletion
                            ? L10n.loading
                            : L10n.cancelDeletion
                    )
                    .font(.subheadline.weight(.semibold))
                }
                .buttonStyle(.plain)
                .foregroundStyle(AppPalette.Primary.main)
                .disabled(viewModel.isCancellingDeletion)
            }
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(AppPalette.Semantic.warning.opacity(0.12))
        )
    }

    private func profileRow(label: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(.caption)
                .foregroundStyle(AppPalette.Neutral.textSecondary)

            Text(value)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(AppPalette.Neutral.textPrimary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func statsGrid(_ stats: UserSeasonStats) -> some View {
        LazyVGrid(
            columns: [GridItem(.flexible()), GridItem(.flexible())],
            spacing: 12
        ) {
            statItem(label: L10n.matchesPlayed, value: stats.matchesPlayed)
            statItem(label: L10n.minutesPlayed, value: stats.minutesPlayed)
            statItem(label: L10n.goals, value: stats.goals)
            statItem(label: L10n.assists, value: stats.assists)
            statItem(label: L10n.ownGoals, value: stats.ownGoals)
            statItem(label: L10n.yellowCards, value: stats.yellowCards)
            statItem(label: L10n.redCards, value: stats.redCards)
            statItem(label: L10n.shotsOnTarget, value: stats.shotsOnTarget)
            statItem(label: L10n.saves, value: stats.saves)
            statItem(label: L10n.substitutionsIn, value: stats.substitutionsIn)
            statItem(label: L10n.substitutionsOut, value: stats.substitutionsOut)
            statItem(label: L10n.injuries, value: stats.injuries)
            statItem(label: L10n.shlag, value: stats.shlagCount)
            statItem(label: L10n.manOfTheMatch, value: stats.manOfTheMatchCount)
            statItem(label: L10n.otherCount, value: stats.otherCount)
        }
    }

    private func statItem(label: String, value: Int) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(.caption2)
                .foregroundStyle(AppPalette.Neutral.textSecondary)
                .lineLimit(2)
                .minimumScaleFactor(0.8)

            Text("\(value)")
                .font(.title3.weight(.bold))
                .foregroundStyle(AppPalette.Primary.main)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(AppPalette.Primary.soft.opacity(0.45))
        )
    }
}

#Preview {
    NavigationStack {
        Profile()
            .background(AuthScreenBackground())
    }
}
