//
//  TeamQuickActionsSection.swift
//  LeVestaire
//

import SwiftUI

struct TeamQuickActionsSection: View {
    @ObservedObject var viewModel: TeamViewModel

    var body: some View {
        HStack(spacing: 12) {
            TeamColoredActionTile(
                title: L10n.text("inviterJoueur"),
                subtitle: L10n.text("invitePlayerActionSubtitle"),
                icon: "envelope.fill",
                tint: AppPalette.Secondary.coral
            ) {
                viewModel.activeSheet = .invitePlayer
            }

            TeamColoredActionTile(
                title: L10n.text("addGuest"),
                subtitle: L10n.text("addGuestActionSubtitle"),
                icon: "person.badge.plus",
                tint: AppPalette.Secondary.mint
            ) {
                viewModel.activeSheet = .addGuest
            }
        }
    }
}
