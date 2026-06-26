//
//  MatchDetailView.swift
//  LeVestaire
//
//  Created by Corentin Robert on 17/06/2026.
//

import SwiftUI

struct MatchDetailView: View {
    let matchId: String
    var onLeave: ((String) -> Void)? = nil

    @StateObject private var viewModel: MatchDetailViewModel
    @State private var showsEditMatchSheet = false

    init(matchId: String, onLeave: ((String) -> Void)? = nil) {
        self.matchId = matchId
        self.onLeave = onLeave
        _viewModel = StateObject(wrappedValue: MatchDetailViewModel(matchId: matchId))
    }

    var body: some View {
        Group {
            if viewModel.isLoading, viewModel.match == nil {
                ProgressView(L10n.matchDetailLoading)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if let match = viewModel.match {
                matchContent(match)
            } else {
                placeholderContent
            }
        }
        .navigationTitle(viewModel.match?.title ?? L10n.matchDetailTitle)
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await viewModel.load()
        }
        .refreshable {
            await viewModel.refreshFromPullToRefresh()
        }
        .onDisappear {
            onLeave?(matchId)
        }
    }

    private func matchContent(_ match: MatchDetail) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                matchHeroCard(match)

                if match.status == .cancelled {
                    cancelledBanner
                }

                if viewModel.showsRespondSection {
                    availabilityRespondSection(match)
                }

                if viewModel.availabilityViewModel.showsPresentMembersList {
                    MatchPresentMembersSection(availabilityViewModel: viewModel.availabilityViewModel)
                }

                if viewModel.showsPrepareHub {
                    MatchPrepareHubSection(viewModel: viewModel)
                }

                if match.status == .upcoming, !viewModel.showsPrepareHub {
                    MatchUpcomingActionsSection(viewModel: viewModel)
                }

                if let tabConfiguration = viewModel.tabConfiguration {
                    MatchDetailTabsSection(
                        viewModel: viewModel,
                        match: match,
                        configuration: tabConfiguration
                    )
                    .id("\(match.id)-\(match.status.rawValue)")
                }

                if let errorMessage = viewModel.errorMessage {
                    Text(errorMessage)
                        .font(.caption)
                        .foregroundStyle(AppPalette.Semantic.error)
                }
            }
            .padding(20)
        }
        .sheet(isPresented: $showsEditMatchSheet) {
            EditMatchSheet(match: match) { updatedMatch in
                viewModel.updateMatchInfo(from: updatedMatch)
            }
        }
    }

    private var cancelledBanner: some View {
        UCard(title: L10n.text("matchCancelled"), icon: "xmark.circle.fill") {
            Text(L10n.text("matchCancelledBeforeStart"))
                .font(.subheadline)
                .foregroundStyle(AppPalette.Neutral.textSecondary)
        }
    }

    private func matchHeroCard(_ match: MatchDetail) -> some View {
        UCard(
            title: match.title,
            icon: "sportscourt.fill",
            trailingHeader: {
                if viewModel.canEditMatchInfo {
                    Button {
                        showsEditMatchSheet = true
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
                    .buttonStyle(.fullTap)
                    .accessibilityLabel(L10n.editMatchInfo)
                }
            }
        ) {
            VStack(alignment: .leading, spacing: 10) {
                HStack(spacing: 8) {
                    Text(match.resolvedStatusLabel)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(AppPalette.Primary.onMain)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(
                            Capsule()
                                .fill(match.status.color)
                        )

                    Spacer(minLength: 0)
                }

                if let homeTeamName = match.homeTeamName, !homeTeamName.isEmpty {
                    Text(homeTeamName)
                        .font(.caption.weight(.medium))
                        .foregroundStyle(AppPalette.Primary.main)
                }

                if let opponentTeam = match.opponentTeam, !opponentTeam.isEmpty {
                    Text("\(L10n.vs) \(opponentTeam)")
                        .font(.headline)
                        .foregroundStyle(AppPalette.Neutral.textPrimary)
                }

                HStack(spacing: 12) {
                    Label(match.toMatchItem().formattedDate, systemImage: "calendar")
                    if let time = match.toMatchItem().formattedTime {
                        Label(time, systemImage: "clock")
                    }
                }
                .font(.caption)
                .foregroundStyle(AppPalette.Neutral.textSecondary)

                if let location = match.location, !location.isEmpty {
                    Label(location, systemImage: "mappin.and.ellipse")
                        .font(.subheadline)
                        .foregroundStyle(AppPalette.Neutral.textSecondary)
                }

                if let scoreText = match.scoreText, match.status == .ongoing || match.status == .finished {
                    Text(scoreText)
                        .font(.title3.weight(.semibold))
                        .foregroundStyle(AppPalette.Primary.main)
                }

                if let summary = match.availabilitySummary,
                   match.status.isPreparationStatus {
                    Text(
                        L10n.availabilityResponsesSummary(
                            responded: summary.respondedCount,
                            total: summary.totalEligible
                        )
                    )
                    .font(.caption)
                    .foregroundStyle(AppPalette.Neutral.textSecondary)
                }
            }
        }
    }

    private func availabilityRespondSection(_ match: MatchDetail) -> some View {
        UCard(title: L10n.text("matchPhaseAvailability"), icon: "person.2.fill") {
            VStack(alignment: .leading, spacing: 12) {
                if let status = match.myAvailabilityStatus {
                    Text(L10n.myAvailabilityResponse(status.displayName))
                        .font(.caption)
                        .foregroundStyle(AppPalette.Neutral.textSecondary)
                }

                HStack(spacing: 8) {
                    ForEach(MatchAvailabilityStatus.allCases, id: \.self) { status in
                        availabilityChip(
                            status: status,
                            isSelected: match.myAvailabilityStatus == status
                        ) {
                            Task { await viewModel.availabilityViewModel.submitMyAvailability(status) }
                        }
                    }
                }
            }
        }
    }

    private func availabilityChip(
        status: MatchAvailabilityStatus,
        isSelected: Bool,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            Text(status.displayName)
                .font(.caption.weight(.semibold))
                .foregroundStyle(isSelected ? AppPalette.Primary.onMain : AppPalette.Primary.main)
                .padding(.horizontal, 10)
                .padding(.vertical, 8)
                .frame(maxWidth: .infinity)
                .background(
                    Capsule()
                        .fill(isSelected ? AppPalette.Primary.main : AppPalette.Primary.soft)
                )
        }
        .buttonStyle(.fullTap)
        .disabled(viewModel.availabilityViewModel.isSubmitting)
    }

    private var placeholderContent: some View {
        ScrollView {
            UCard(title: L10n.matchDetailTitle, icon: "sportscourt.fill") {
                Text(viewModel.errorMessage ?? L10n.matchDetailPlaceholder)
                    .font(.subheadline)
                    .foregroundStyle(AppPalette.Neutral.textSecondary)
            }
            .padding(20)
        }
    }
}

#Preview {
    NavigationStack {
        MatchDetailView(matchId: "preview-match")
            .environmentObject(LocalizationManager.shared)
            .environment(\.locale, LocalizationManager.shared.locale)
    }
}
