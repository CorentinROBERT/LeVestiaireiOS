//
//  TeamRankingsSection.swift
//  LeVestaire
//

import SwiftUI

struct TeamRankingsSection: View {
    @ObservedObject var statsViewModel: TeamStatsViewModel

    init(viewModel: TeamViewModel) {
        self.statsViewModel = viewModel.statsViewModel
    }

    var body: some View {
        UCard(title: L10n.text("leaderboard"), icon: "list.number") {
            VStack(alignment: .leading, spacing: 16) {
                TeamSeasonPicker(
                    availableSeasons: statsViewModel.availableSeasons,
                    selection: $statsViewModel.selectedRankingSeason,
                    onChange: {
                        Task { await statsViewModel.onRankingSeasonChanged() }
                    }
                )

                Picker(L10n.text("leaderboard"), selection: $statsViewModel.selectedRankingKind) {
                    ForEach(TeamRankingKind.allCases) { kind in
                        Text(kind.title).tag(kind)
                    }
                }
                .pickerStyle(.segmented)

                if statsViewModel.isLoadingRankings, statsViewModel.teamRankings == nil {
                    TeamLoadingPlaceholder()
                } else if let error = statsViewModel.rankingsLoadError {
                    TeamSectionErrorView(message: error) {
                        Task { await statsViewModel.retryRankings() }
                    }
                } else {
                    let entries = statsViewModel.rankingEntries(for: statsViewModel.selectedRankingKind)
                    if entries.isEmpty {
                        TeamEmptyState(
                            icon: "trophy",
                            title: L10n.text("emptyRankingsTitle"),
                            message: L10n.noStatisticsAvailable
                        )
                    } else {
                        if entries.count == 1 {
                            rankingRow(rank: 1, entry: entries[0])
                        } else {
                            if entries.count >= 2 {
                                TeamPodiumView(entries: Array(entries.prefix(3)))
                            }

                            ForEach(Array(entries.dropFirst(3).enumerated()), id: \.element.id) { index, entry in
                                rankingRow(rank: index + 4, entry: entry)
                            }
                        }
                    }
                }
            }
        }
    }

    private func rankingRow(rank: Int, entry: RankingPlayerEntry) -> some View {
        HStack(spacing: 12) {
            Text("\(rank)")
                .font(.subheadline.weight(.bold))
                .foregroundStyle(AppPalette.Primary.main)
                .frame(width: 24)

            Text(entry.displayName.isEmpty ? "—" : entry.displayName)
                .font(.subheadline)
                .foregroundStyle(AppPalette.Neutral.textPrimary)

            if entry.isGuest {
                TeamGuestBadge()
            }

            Spacer()

            Text("\(entry.scoreValue)")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(AppPalette.Primary.dark)
        }
        .padding(.vertical, 4)
        .accessibilityElement(children: .combine)
    }
}

#if DEBUG
#Preview {
    TeamRankingsSection(viewModel: .preview())
        .padding()
        .teamPreviewEnvironment()
}
#endif
