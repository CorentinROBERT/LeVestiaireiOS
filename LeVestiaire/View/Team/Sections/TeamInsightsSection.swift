//
//  TeamInsightsSection.swift
//  LeVestaire
//

import SwiftUI

struct TeamInsightsSection: View {
    @ObservedObject var statsViewModel: TeamStatsViewModel

    var body: some View {
        UCard(title: L10n.text("teamInsights"), icon: "sparkles") {
            VStack(alignment: .leading, spacing: 16) {
                if statsViewModel.isLoadingInsights, statsViewModel.teamInsights == nil {
                    TeamLoadingPlaceholder()
                } else if let error = statsViewModel.insightsLoadError, statsViewModel.teamInsights == nil {
                    TeamSectionErrorView(message: error) {
                        Task { await statsViewModel.retryStats() }
                    }
                } else if let insights = statsViewModel.teamInsights, insights.hasContent {
                    if let form = insights.form, form.hasContent {
                        formSection(form)
                    }

                    if let streak = insights.streak {
                        streakSection(streak)
                    }

                    if let summary = insights.seasonSummary, summary.hasContent {
                        seasonSummarySection(summary)
                    }

                    if let playerOfMoment = insights.playerOfMoment, playerOfMoment.hasContent {
                        playerOfMomentSection(playerOfMoment)
                    }

                    if let availability = insights.availability, availability.hasContent {
                        availabilitySection(availability)
                    }

                    if let nextMatch = insights.nextMatch, nextMatch.hasContent {
                        nextMatchSection(nextMatch)
                    }
                } else {
                    TeamEmptyState(
                        icon: "sparkles",
                        title: L10n.text("emptyInsightsTitle"),
                        message: L10n.text("noInsightsAvailable")
                    )
                }
            }
        }
    }

    @ViewBuilder
    private func formSection(_ form: TeamFormInsights) -> some View {
        insightBlock(title: L10n.text("recentForm")) {
            if !form.results.isEmpty {
                HStack(spacing: 8) {
                    ForEach(Array(form.results.enumerated()), id: \.offset) { _, result in
                        Text(result.shortLabel)
                            .font(.caption.weight(.bold))
                            .foregroundStyle(.white)
                            .frame(width: 28, height: 28)
                            .background(resultColor(result), in: Circle())
                            .accessibilityLabel(resultAccessibilityLabel(result))
                    }
                }
            }

            HStack(spacing: 12) {
                insightMetric(label: L10n.text("points"), value: "\(form.points)")
                insightMetric(label: L10n.text("goalsFor"), value: "\(form.goalsFor)")
                insightMetric(label: L10n.text("goalsAgainst"), value: "\(form.goalsAgainst)")
            }
        }
    }

    private func streakSection(_ streak: TeamStreakInsights) -> some View {
        insightBlock(title: L10n.text("currentStreak")) {
            Label(streakLabel(streak), systemImage: streakIcon(streak.type))
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(AppPalette.Primary.dark)
        }
    }

    private func seasonSummarySection(_ summary: TeamSeasonSummaryInsights) -> some View {
        insightBlock(title: L10n.text("seasonBalance")) {
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                TeamStatCell(title: L10n.matchesPlayed, value: summary.played)
                TeamStatCell(title: L10n.text("wins"), value: summary.wins)
                TeamStatCell(title: L10n.text("draws"), value: summary.draws)
                TeamStatCell(title: L10n.text("losses"), value: summary.losses)
                TeamStatCell(title: L10n.text("goalsFor"), value: summary.goalsFor)
                TeamStatCell(title: L10n.text("goalsAgainst"), value: summary.goalsAgainst)
                TeamStatCell(title: L10n.text("points"), value: summary.points)
            }
        }
    }

    private func playerOfMomentSection(_ playerOfMoment: TeamPlayerOfMomentInsights) -> some View {
        insightBlock(title: L10n.text("playerOfMoment")) {
            if let player = playerOfMoment.player {
                HStack(spacing: 12) {
                    TeamMemberAvatar(initials: player.initials)

                    VStack(alignment: .leading, spacing: 4) {
                        HStack(spacing: 6) {
                            Text(player.displayName.isEmpty ? "—" : player.displayName)
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(AppPalette.Neutral.textPrimary)

                            if player.isGuest {
                                TeamGuestBadge()
                            }
                        }

                        Text(playerOfMomentScopeLabel(playerOfMoment.scope))
                            .font(.caption)
                            .foregroundStyle(AppPalette.Neutral.textSecondary)
                    }

                    Spacer()

                    VStack(alignment: .trailing, spacing: 4) {
                        Text("\(playerOfMoment.goals) / \(playerOfMoment.assists)")
                            .font(.subheadline.weight(.bold))
                            .foregroundStyle(AppPalette.Primary.dark)
                        Text(L10n.text("goalsAssistsShort"))
                            .font(.caption2)
                            .foregroundStyle(AppPalette.Neutral.textSecondary)
                    }
                }
            }
        }
    }

    private func availabilitySection(_ availability: TeamAvailabilityInsights) -> some View {
        insightBlock(title: L10n.text("availabilityInsights")) {
            VStack(alignment: .leading, spacing: 8) {
                if let average = availability.formattedPercent(availability.averageResponseRate) {
                    availabilityRow(
                        label: L10n.text("averageResponseRate"),
                        value: average
                    )
                }
                if let nextMatch = availability.formattedPercent(availability.nextMatchResponseRate) {
                    availabilityRow(
                        label: L10n.text("nextMatchResponseRate"),
                        value: nextMatch
                    )
                }
            }
        }
    }

    private func nextMatchSection(_ nextMatch: TeamNextMatchInsights) -> some View {
        insightBlock(title: L10n.text("nextMatch")) {
            if let match = nextMatch.match {
                VStack(alignment: .leading, spacing: 8) {
                    Text(match.displayTitle)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(AppPalette.Neutral.textPrimary)

                    if let date = match.date {
                        Text(formattedMatchDate(date, startTime: match.startTime))
                            .font(.caption)
                            .foregroundStyle(AppPalette.Neutral.textSecondary)
                    }
                }
            }

            if let availability = nextMatch.availability, availability.hasContent {
                HStack(spacing: 12) {
                    availabilityChip(
                        label: L10n.text("availableShort"),
                        value: availability.available,
                        color: AppPalette.Semantic.success
                    )
                    availabilityChip(
                        label: L10n.text("absentShort"),
                        value: availability.absent,
                        color: AppPalette.Secondary.coral
                    )
                    availabilityChip(
                        label: L10n.text("unknownShort"),
                        value: availability.unknown,
                        color: AppPalette.Neutral.textSecondary
                    )
                }
            }
        }
    }

    private func insightBlock<Content: View>(
        title: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(AppPalette.Neutral.textPrimary)

            content()
        }
    }

    private func insightMetric(label: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label)
                .font(.caption)
                .foregroundStyle(AppPalette.Neutral.textSecondary)
            Text(value)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(AppPalette.Primary.dark)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func availabilityRow(label: String, value: String) -> some View {
        HStack {
            Text(label)
                .font(.caption)
                .foregroundStyle(AppPalette.Neutral.textSecondary)
            Spacer()
            Text(value)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(AppPalette.Primary.dark)
        }
    }

    private func availabilityChip(label: String, value: Int, color: Color) -> some View {
        VStack(spacing: 4) {
            Text("\(value)")
                .font(.subheadline.weight(.bold))
                .foregroundStyle(color)
            Text(label)
                .font(.caption2)
                .foregroundStyle(AppPalette.Neutral.textSecondary)
        }
        .frame(maxWidth: .infinity)
    }

    private func resultColor(_ result: TeamMatchResult) -> Color {
        switch result {
        case .win:
            return AppPalette.Semantic.success
        case .draw:
            return AppPalette.Semantic.warning
        case .loss:
            return AppPalette.Secondary.coral
        }
    }

    private func resultAccessibilityLabel(_ result: TeamMatchResult) -> String {
        switch result {
        case .win:
            return L10n.text("matchResultWin")
        case .draw:
            return L10n.text("matchResultDraw")
        case .loss:
            return L10n.text("matchResultLoss")
        }
    }

    private func streakLabel(_ streak: TeamStreakInsights) -> String {
        switch streak.type {
        case .win:
            return L10n.format("streakWin", streak.count)
        case .loss:
            return L10n.format("streakLoss", streak.count)
        case .unbeaten:
            return L10n.format("streakUnbeaten", streak.count)
        case .winless:
            return L10n.format("streakWinless", streak.count)
        }
    }

    private func streakIcon(_ type: TeamStreakType) -> String {
        switch type {
        case .win, .unbeaten:
            return "flame.fill"
        case .loss, .winless:
            return "arrow.down.right.circle"
        }
    }

    private func playerOfMomentScopeLabel(_ scope: TeamPlayerOfMomentScope?) -> String {
        switch scope {
        case .recent:
            return L10n.text("playerOfMomentRecent")
        case .season, .none:
            return L10n.text("playerOfMomentSeason")
        }
    }

    private func formattedMatchDate(_ date: Date, startTime: String?) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale.current
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        let dateText = formatter.string(from: date)
        if let startTime, !startTime.isEmpty {
            return "\(dateText) · \(startTime)"
        }
        return dateText
    }
}

#if DEBUG
#Preview {
    TeamInsightsSection(statsViewModel: TeamViewModel.preview().statsViewModel)
        .padding()
        .teamPreviewEnvironment()
}
#endif
