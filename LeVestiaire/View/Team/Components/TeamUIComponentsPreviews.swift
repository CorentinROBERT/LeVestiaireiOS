//
//  TeamUIComponentsPreviews.swift
//  LeVestaire
//

#if DEBUG
import SwiftUI

#Preview("Avatars & badges") {
    HStack(spacing: 12) {
        TeamMemberAvatar(initials: "CR")
        TeamRoleBadge(role: .admin)
        TeamJerseyBadge(number: 10)
        TeamGuestBadge()
    }
    .padding()
    .teamPreviewEnvironment()
}

#Preview("Stats & KPI") {
    VStack(spacing: 16) {
        TeamStatCell(title: L10n.goals, value: 12)
        TeamKPITile(value: "8", label: L10n.matchesPlayed)
        TeamCollapsedStat(label: L10n.assists, value: 5)
        TeamPlayerStatBadge(label: L10n.goals, value: 3)
        TeamInfoChip(title: L10n.season, value: TeamPreviewData.season)
    }
    .padding()
    .teamPreviewEnvironment()
}

#Preview("States & actions") {
    VStack(spacing: 16) {
        TeamEmptyState(
            icon: "chart.bar",
            title: L10n.text("statistics"),
            message: L10n.noStatisticsAvailable
        )
        TeamLoadingPlaceholder(rowCount: 2)
        TeamColoredActionTile(
            title: L10n.text("invitePlayer"),
            subtitle: L10n.text("invitePlayerActionSubtitle"),
            icon: "person.badge.plus",
            tint: AppPalette.Primary.main,
            action: {}
        )
        TeamSectionErrorView(message: L10n.retry) {}
    }
    .padding()
    .teamPreviewEnvironment()
}

#Preview("Podium") {
    TeamPodiumView(entries: TeamPreviewData.rankings.scorers)
        .padding()
        .teamPreviewEnvironment()
}
#endif
