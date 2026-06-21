//
//  MatchQuizLeaderboardView.swift
//  LeVestaire
//

import SwiftUI

struct MatchQuizLeaderboardView: View {
    let entries: [MatchQuizLeaderboardEntry]
    var counts: MatchQuizLeaderboardCounts?

    var body: some View {
        if entries.isEmpty {
            TeamEmptyState(
                icon: "list.number",
                title: L10n.text("leaderboard"),
                message: emptyMessage
            )
        } else {
            VStack(alignment: .leading, spacing: 10) {
                header

                ForEach(Array(entries.enumerated()), id: \.element.id) { offset, entry in
                    HStack(spacing: 12) {
                        Text(entry.rank.map { "\($0)" } ?? "\(offset + 1)")
                            .font(.headline.weight(.bold))
                            .foregroundStyle(AppPalette.Primary.main)
                            .frame(width: 28)

                        VStack(alignment: .leading, spacing: 2) {
                            Text(entry.displayName)
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(AppPalette.Neutral.textPrimary)

                            Text(
                                L10n.format(
                                    "youHaveMadeAttempts",
                                    entry.attemptCount
                                )
                            )
                            .font(.caption)
                            .foregroundStyle(AppPalette.Neutral.textSecondary)
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
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(L10n.text("leaderboard"))
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(AppPalette.Neutral.textPrimary)

            if let countsSummary {
                Text(countsSummary)
                    .font(.caption)
                    .foregroundStyle(AppPalette.Neutral.textSecondary)
            }
        }
    }

    private var emptyMessage: String {
        if let countsSummary {
            return countsSummary
        }
        return L10n.text("emptyRankingsTitle")
    }

    private var countsSummary: String? {
        guard let counts else { return nil }

        var parts: [String] = []
        if let participants = counts.participants {
            parts.append(L10n.format("quizParticipantsCount", participants))
        }
        if let eligible = counts.eligible {
            parts.append(L10n.format("quizEligibleCount", eligible))
        }
        return parts.isEmpty ? nil : parts.joined(separator: " · ")
    }
}

#if DEBUG
#Preview {
    MatchQuizLeaderboardView(
        entries: [
            MatchQuizLeaderboardEntry(displayName: "Lucas", attemptCount: 3, rank: 1)
        ],
        counts: nil
    )
    .padding()
    .teamPreviewEnvironment()
}
#endif
