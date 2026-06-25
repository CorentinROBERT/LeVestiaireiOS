//
//  TeamDuosSection.swift
//  LeVestaire
//

import SwiftUI

struct TeamDuosSection: View {
    @ObservedObject var statsViewModel: TeamStatsViewModel

    var body: some View {
        UCard(title: L10n.text("topDuos"), icon: "person.2.fill") {
            VStack(alignment: .leading, spacing: 16) {
                if statsViewModel.isLoadingDuos, statsViewModel.teamDuos == nil {
                    TeamLoadingPlaceholder()
                } else if let error = statsViewModel.duosLoadError, statsViewModel.teamDuos == nil {
                    TeamSectionErrorView(message: error) {
                        Task { await statsViewModel.retryStats() }
                    }
                } else if let duos = statsViewModel.teamDuos, duos.hasContent {
                    ForEach(duos.duos) { duo in
                        duoRow(duo)
                    }
                } else {
                    TeamEmptyState(
                        icon: "person.2",
                        title: L10n.text("emptyDuosTitle"),
                        message: L10n.text("noDuosAvailable")
                    )
                }
            }
        }
    }

    private func duoRow(_ duo: TeamSeasonDuoEntry) -> some View {
        HStack(spacing: 12) {
            HStack(spacing: -8) {
                TeamMemberAvatar(initials: duo.playerA.initials, size: 36)
                TeamMemberAvatar(initials: duo.playerB.initials, size: 36)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(duoNames(duo))
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(AppPalette.Neutral.textPrimary)

                Text(L10n.format("duoGoalsTogether", duo.goalsTogether))
                    .font(.caption)
                    .foregroundStyle(AppPalette.Neutral.textSecondary)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 4) {
                Text("\(duo.totalCombos)")
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(AppPalette.Primary.dark)
                Text(L10n.text("duoCombos"))
                    .font(.caption2)
                    .foregroundStyle(AppPalette.Neutral.textSecondary)
            }
        }
        .padding(.vertical, 4)
        .accessibilityElement(children: .combine)
    }

    private func duoNames(_ duo: TeamSeasonDuoEntry) -> String {
        let nameA = duo.playerA.displayName.isEmpty ? "—" : duo.playerA.displayName
        let nameB = duo.playerB.displayName.isEmpty ? "—" : duo.playerB.displayName
        return "\(nameA) · \(nameB)"
    }
}

#if DEBUG
#Preview {
    TeamDuosSection(statsViewModel: TeamViewModel.preview().statsViewModel)
        .padding()
        .teamPreviewEnvironment()
}
#endif
