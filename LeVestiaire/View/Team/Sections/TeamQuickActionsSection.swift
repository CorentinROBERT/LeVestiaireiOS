//
//  TeamQuickActionsSection.swift
//  LeVestaire
//

import SwiftUI

struct TeamQuickActionsSection: View {
    @ObservedObject var viewModel: TeamViewModel

    private let pairedActionColumns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12)
    ]

    var body: some View {
        VStack(spacing: 12) {
            LazyVGrid(columns: pairedActionColumns, spacing: 12) {
                TeamColoredActionTile(
                    title: L10n.text("inviterJoueur"),
                    subtitle: L10n.text("invitePlayerActionSubtitle"),
                    icon: "envelope.fill",
                    tint: AppPalette.Secondary.coral
                ) {
                    viewModel.activeSheet = .invitePlayer
                }
                .frame(maxHeight: .infinity, alignment: .topLeading)

                TeamColoredActionTile(
                    title: L10n.text("addGuest"),
                    subtitle: L10n.text("addGuestActionSubtitle"),
                    icon: "person.badge.plus",
                    tint: AppPalette.Secondary.mint
                ) {
                    viewModel.activeSheet = .addGuest
                }
                .frame(maxHeight: .infinity, alignment: .topLeading)
            }

            TeamColoredActionTile(
                title: L10n.text("shareTeamInviteLink"),
                subtitle: L10n.text("shareTeamInviteActionSubtitle"),
                icon: "ticket.fill",
                tint: AppPalette.Primary.main
            ) {
                viewModel.presentShareTeamInviteSheet()
            }
        }
    }
}

#if DEBUG
#Preview {
    TeamQuickActionsSection(viewModel: .preview())
        .padding()
        .teamPreviewEnvironment()
}
#endif
