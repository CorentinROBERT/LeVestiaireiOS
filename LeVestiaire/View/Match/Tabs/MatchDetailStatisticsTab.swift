//
//  MatchDetailStatisticsTab.swift
//  LeVestaire
//

import SwiftUI

struct MatchDetailStatisticsTab: View {
    @ObservedObject var statisticsViewModel: MatchDetailStatisticsViewModel
    let match: MatchDetail

    init(viewModel: MatchDetailViewModel, match: MatchDetail) {
        self.statisticsViewModel = viewModel.statisticsViewModel
        self.match = match
    }

    var body: some View {
        Group {
            if match.status == .upcoming {
                TeamEmptyState(
                    icon: "chart.bar.fill",
                    title: L10n.text("statistics"),
                    message: L10n.text("matchStatsAvailableAfterMatch")
                )
            } else if statisticsViewModel.isLoadingMatchStats, statisticsViewModel.matchStats == nil {
                ProgressView(L10n.loading)
                    .frame(maxWidth: .infinity, minHeight: 120)
            } else if let stats = statisticsViewModel.matchStats, stats.hasContent {
                statsContent(stats)
            } else {
                TeamEmptyState(
                    icon: "chart.bar",
                    title: L10n.text("statistics"),
                    message: L10n.noStatisticsAvailable
                )
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .task {
            await statisticsViewModel.loadIfNeeded()
        }
    }

    private func statsContent(_ stats: MatchStatsPayload) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            if stats.resolvedTotals.hasAnyValue {
                matchTotalsGrid(stats.resolvedTotals)
            }

            if !stats.sortedPlayers.isEmpty {
                Text(L10n.text("playerStatistics"))
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(AppPalette.Neutral.textPrimary)

                ForEach(stats.sortedPlayers) { player in
                    playerStatsRow(player)
                }
            }
        }
    }

    private func matchTotalsGrid(_ totals: TeamSeasonStatsTotals) -> some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
            if totals.goals > 0 { TeamStatCell(title: L10n.goals, value: totals.goals) }
            if totals.ownGoals > 0 { TeamStatCell(title: L10n.text("ownGoals"), value: totals.ownGoals) }
            if totals.assists > 0 { TeamStatCell(title: L10n.assists, value: totals.assists) }
            if totals.yellowCards > 0 { TeamStatCell(title: L10n.yellowCards, value: totals.yellowCards) }
            if totals.redCards > 0 { TeamStatCell(title: L10n.redCards, value: totals.redCards) }
            if totals.substitutionsIn > 0 { TeamStatCell(title: L10n.text("substitutionsIn"), value: totals.substitutionsIn) }
            if totals.substitutionsOut > 0 { TeamStatCell(title: L10n.text("substitutionsOut"), value: totals.substitutionsOut) }
            if totals.shotsOnTarget > 0 { TeamStatCell(title: L10n.shotsOnTarget, value: totals.shotsOnTarget) }
            if totals.saves > 0 { TeamStatCell(title: L10n.saves, value: totals.saves) }
            if totals.injuries > 0 { TeamStatCell(title: L10n.text("injury"), value: totals.injuries) }
            if totals.shlagCount > 0 { TeamStatCell(title: L10n.text("shlag"), value: totals.shlagCount) }
            if totals.manOfTheMatchCount > 0 { TeamStatCell(title: L10n.manOfTheMatch, value: totals.manOfTheMatchCount) }
            if totals.otherCount > 0 { TeamStatCell(title: L10n.text("other"), value: totals.otherCount) }
        }
    }

    private func playerStatsRow(_ player: TeamPlayerSeasonStats) -> some View {
        HStack(spacing: 12) {
            TeamMemberAvatar(initials: player.initials)

            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 6) {
                    Text(player.displayName)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(AppPalette.Neutral.textPrimary)

                    if player.isGuest {
                        TeamGuestBadge()
                    }
                }

                if player.hasMatchStatistics {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            ForEach(Array(player.matchStatEntries.enumerated()), id: \.offset) { _, entry in
                                TeamPlayerStatBadge(label: entry.label, value: entry.value)
                            }
                        }
                    }
                }
            }

            Spacer(minLength: 0)
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(AppPalette.Neutral.surface)
        )
    }
}

#if DEBUG
#Preview {
    MatchDetailStatisticsTab(
        viewModel: .preview(status: .finished),
        match: MatchPreviewData.detail(status: .finished)
    )
    .padding()
    .teamPreviewEnvironment()
}
#endif
