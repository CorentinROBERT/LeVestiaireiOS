//
//  TeamInvitationsSection.swift
//  LeVestaire
//

import SwiftUI

struct TeamInvitationsSection: View {
    @ObservedObject var viewModel: TeamViewModel

    var body: some View {
        UCard(
            title: L10n.format("sentInvitations", viewModel.teamInvitations.count),
            icon: "envelope.open.fill"
        ) {
            if viewModel.isLoadingInvitations {
                TeamLoadingPlaceholder(rowCount: 2)
            } else if let error = viewModel.invitationsLoadError {
                TeamSectionErrorView(message: error) {
                    Task { await viewModel.retryInvitations() }
                }
            } else if viewModel.teamInvitations.isEmpty {
                TeamEmptyState(
                    icon: "envelope",
                    title: L10n.text("noInvitationsSent"),
                    actionTitle: L10n.text("inviterJoueur"),
                    action: {
                        viewModel.activeSheet = .invitePlayer
                    }
                )
            } else {
                VStack(spacing: 12) {
                    ForEach(viewModel.teamInvitations) { invitation in
                        invitationRow(invitation)
                    }
                }
            }
        }
    }

    private func invitationRow(_ invitation: TeamInvitation) -> some View {
        HStack(alignment: .top, spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(invitation.displayName)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(AppPalette.Neutral.textPrimary)

                if !invitation.subtitle.isEmpty {
                    Text(invitation.subtitle)
                        .font(.caption)
                        .foregroundStyle(AppPalette.Neutral.textSecondary)
                }

                let statusColor = TeamInvitationStatusStyle.color(for: invitation.status)
                Text(invitation.status.localizedLabel)
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(statusColor)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(statusColor.opacity(0.12))
                    .clipShape(Capsule())
            }

            Spacer(minLength: 0)

            if invitation.status.canManage {
                Menu {
                    Button(L10n.text("resend")) {
                        Task { await viewModel.resendInvitation(invitation) }
                    }
                    Button(L10n.text("cancelInvitation"), role: .destructive) {
                        viewModel.confirmCancelInvitation(invitation)
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                        .font(.title3)
                        .foregroundStyle(AppPalette.Primary.main)
                }
            }
        }
        .padding(12)
        .glassEffect(.regular, in: .rect(cornerRadius: 14))
    }
}
