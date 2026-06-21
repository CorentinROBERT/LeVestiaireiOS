//
//  TeamStatsSection.swift
//  LeVestaire
//

import SwiftUI

struct TeamStatsSection: View {
    @ObservedObject var viewModel: TeamViewModel

    var body: some View {
        UCard(title: L10n.text("teamStatistics"), icon: "chart.bar.fill") {
            VStack(alignment: .leading, spacing: 16) {
                TeamSeasonPicker(
                    availableSeasons: viewModel.availableSeasons,
                    selection: $viewModel.selectedStatsSeason,
                    onChange: {
                        Task { await viewModel.onStatsSeasonChanged() }
                    }
                )

                if viewModel.isLoadingStats, viewModel.teamSeasonStats == nil {
                    TeamLoadingPlaceholder()
                } else if let error = viewModel.statsLoadError {
                    TeamSectionErrorView(message: error) {
                        Task { await viewModel.retryStats() }
                    }
                } else if let stats = viewModel.teamSeasonStats, stats.hasContent {
                    Text(L10n.text("seasonStats"))
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(AppPalette.Neutral.textPrimary)

                    teamTotalsGrid(stats.totals, matchesPlayed: stats.totalMatchesPlayed)

                    if !stats.sortedPlayers.isEmpty {
                        Text(L10n.text("playerStatistics"))
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(AppPalette.Neutral.textPrimary)
                            .padding(.top, 4)

                        ForEach(stats.sortedPlayers) { player in
                            playerStatsRow(player)
                        }
                    }
                } else {
                    TeamEmptyState(
                        icon: "chart.bar",
                        title: L10n.text("emptyStatsTitle"),
                        message: L10n.noStatisticsAvailable
                    )
                }
            }
        }
    }

    private func teamTotalsGrid(_ totals: TeamSeasonStatsTotals, matchesPlayed: Int) -> some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
            TeamStatCell(title: L10n.matchesPlayed, value: matchesPlayed)
            TeamStatCell(title: L10n.goals, value: totals.goals)
            TeamStatCell(title: L10n.assists, value: totals.assists)
            TeamStatCell(title: L10n.yellowCards, value: totals.yellowCards)
            TeamStatCell(title: L10n.redCards, value: totals.redCards)
            TeamStatCell(title: L10n.minutesPlayed, value: totals.minutesPlayed)
            TeamStatCell(title: L10n.shotsOnTarget, value: totals.shotsOnTarget)
            TeamStatCell(title: L10n.saves, value: totals.saves)
            TeamStatCell(title: L10n.manOfTheMatch, value: totals.manOfTheMatchCount)
        }
    }

    private func playerStatsRow(_ player: TeamPlayerSeasonStats) -> some View {
        HStack(spacing: 12) {
            TeamMemberAvatar(initials: player.initials)

            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Text(player.displayName)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(AppPalette.Neutral.textPrimary)

                    if player.isGuest {
                        TeamGuestBadge()
                    }
                }

                HStack(spacing: 12) {
                    TeamPlayerStatBadge(label: L10n.matchesPlayed, value: player.matchesPlayed)
                    TeamPlayerStatBadge(label: L10n.goals, value: player.goals)
                    TeamPlayerStatBadge(label: L10n.assists, value: player.assists)
                    TeamPlayerStatBadge(label: L10n.minutesPlayed, value: player.minutesPlayed)
                }
            }

            Spacer(minLength: 0)
        }
        .padding(.vertical, 4)
    }
}

#if DEBUG
#Preview {
    TeamStatsSection(viewModel: .preview())
        .teamPreviewEnvironment()
}
#endif
