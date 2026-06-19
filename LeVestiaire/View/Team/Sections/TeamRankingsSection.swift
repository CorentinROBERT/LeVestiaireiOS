//
//  TeamRankingsSection.swift
//  LeVestaire
//

import SwiftUI

struct TeamRankingsSection: View {
    @ObservedObject var viewModel: TeamViewModel

    var body: some View {
        UCard(title: L10n.text("leaderboard"), icon: "list.number") {
            VStack(alignment: .leading, spacing: 16) {
                TeamSeasonPicker(
                    availableSeasons: viewModel.availableSeasons,
                    selection: $viewModel.selectedRankingSeason,
                    onChange: {
                        Task { await viewModel.onRankingSeasonChanged() }
                    }
                )

                Picker(L10n.text("leaderboard"), selection: $viewModel.selectedRankingKind) {
                    ForEach(TeamRankingKind.allCases) { kind in
                        Text(kind.title).tag(kind)
                    }
                }
                .pickerStyle(.segmented)

                if viewModel.isLoadingRankings, viewModel.teamRankings == nil {
                    TeamLoadingPlaceholder()
                } else if let error = viewModel.rankingsLoadError {
                    TeamSectionErrorView(message: error) {
                        Task { await viewModel.retryRankings() }
                    }
                } else {
                    let entries = viewModel.rankingEntries(for: viewModel.selectedRankingKind)
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
    }
}
