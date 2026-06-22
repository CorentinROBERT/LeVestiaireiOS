//
//  TeamKPISection.swift
//  LeVestaire
//

import SwiftUI

struct TeamKPISection: View {
    @ObservedObject var viewModel: TeamViewModel
    @ObservedObject var statsViewModel: TeamStatsViewModel

    init(viewModel: TeamViewModel) {
        self.viewModel = viewModel
        self.statsViewModel = viewModel.statsViewModel
    }

    var body: some View {
        HStack(spacing: 8) {
            if statsViewModel.isLoadingKPIs {
                ForEach(0..<4, id: \.self) { _ in
                    RoundedRectangle(cornerRadius: 16)
                        .fill(AppPalette.Primary.soft.opacity(0.45))
                        .frame(maxWidth: .infinity)
                        .frame(height: 84)
                }
                .redacted(reason: .placeholder)
            } else {
                TeamKPITile(
                    value: statsViewModel.kpiMatchesPlayedDisplay,
                    label: L10n.matchesPlayed,
                    accent: AppPalette.Primary.main,
                    isUnavailable: statsViewModel.statsKPIsUnavailable
                )
                TeamKPITile(
                    value: statsViewModel.kpiGoalsDisplay,
                    label: L10n.goals,
                    accent: AppPalette.Secondary.coral,
                    isUnavailable: statsViewModel.statsKPIsUnavailable
                )
                TeamKPITile(
                    value: statsViewModel.kpiAssistsDisplay,
                    label: L10n.assists,
                    accent: AppPalette.Secondary.mint,
                    isUnavailable: statsViewModel.statsKPIsUnavailable
                )
                TeamKPITile(
                    value: viewModel.kpiMemberCountDisplay,
                    label: L10n.text("members"),
                    accent: AppPalette.Primary.dark
                )
            }
        }
    }
}

#if DEBUG
#Preview {
    TeamKPISection(viewModel: .preview())
        .padding()
        .teamPreviewEnvironment()
}
#endif
