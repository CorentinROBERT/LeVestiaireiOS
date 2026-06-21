//
//  TeamKPISection.swift
//  LeVestaire
//

import SwiftUI

struct TeamKPISection: View {
    @ObservedObject var viewModel: TeamViewModel

    var body: some View {
        HStack(spacing: 8) {
            if viewModel.isLoadingKPIs {
                ForEach(0..<4, id: \.self) { _ in
                    RoundedRectangle(cornerRadius: 16)
                        .fill(AppPalette.Primary.soft.opacity(0.45))
                        .frame(maxWidth: .infinity)
                        .frame(height: 84)
                }
                .redacted(reason: .placeholder)
            } else {
                TeamKPITile(
                    value: viewModel.kpiMatchesPlayedDisplay,
                    label: L10n.matchesPlayed,
                    accent: AppPalette.Primary.main,
                    isUnavailable: viewModel.statsKPIsUnavailable
                )
                TeamKPITile(
                    value: viewModel.kpiGoalsDisplay,
                    label: L10n.goals,
                    accent: AppPalette.Secondary.coral,
                    isUnavailable: viewModel.statsKPIsUnavailable
                )
                TeamKPITile(
                    value: viewModel.kpiAssistsDisplay,
                    label: L10n.assists,
                    accent: AppPalette.Secondary.mint,
                    isUnavailable: viewModel.statsKPIsUnavailable
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
