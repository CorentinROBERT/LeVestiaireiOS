//
//  TeamInvitationsSection.swift
//  LeVestaire
//

import SwiftUI

struct TeamInvitationsSection: View {
    @ObservedObject var viewModel: TeamViewModel
    @ObservedObject var invitationsViewModel: TeamInvitationsViewModel
    @State private var isExpanded = false

    init(viewModel: TeamViewModel) {
        self.viewModel = viewModel
        self.invitationsViewModel = viewModel.invitationsViewModel
    }

    var body: some View {
        UCard {
            VStack(alignment: .leading, spacing: isExpanded ? 16 : 12) {
                headerButton

                if isExpanded {
                    expandedContent
                } else {
                    collapsedSummary
                }
            }
        }
    }

    private var headerButton: some View {
        Button {
            withAnimation(.easeInOut(duration: 0.25)) {
                isExpanded.toggle()
            }
            TeamHaptics.lightImpact()
        } label: {
            HStack(spacing: 10) {
                Image(systemName: "envelope.open.fill")
                    .foregroundStyle(AppPalette.Primary.main)

                Text(L10n.format("sentInvitations", invitationsViewModel.teamInvitations.count))
                    .font(.headline)
                    .foregroundStyle(AppPalette.Primary.dark)

                Spacer(minLength: 0)

                if invitationsViewModel.isLoadingInvitations {
                    ProgressView()
                        .controlSize(.small)
                }

                Image(systemName: "chevron.down")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(AppPalette.Neutral.textSecondary)
                    .rotationEffect(.degrees(isExpanded ? 180 : 0))
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder
    private var collapsedSummary: some View {
        if let error = invitationsViewModel.invitationsLoadError {
            TeamSectionErrorText(message: error)
        } else if invitationsViewModel.isLoadingInvitations {
            Text(L10n.loading)
                .font(.caption)
                .foregroundStyle(AppPalette.Neutral.textSecondary)
        } else if invitationsViewModel.teamInvitations.isEmpty {
            Text(L10n.text("noInvitationsSent"))
                .font(.caption)
                .foregroundStyle(AppPalette.Neutral.textSecondary)
        } else {
            Text(pendingInvitationsSummary)
                .font(.caption)
                .foregroundStyle(AppPalette.Neutral.textSecondary)
        }
    }

    @ViewBuilder
    private var expandedContent: some View {
        if invitationsViewModel.isLoadingInvitations {
            TeamLoadingPlaceholder(rowCount: 2)
        } else if let error = invitationsViewModel.invitationsLoadError {
            TeamSectionErrorView(message: error) {
                Task { await invitationsViewModel.retry() }
            }
        } else if invitationsViewModel.teamInvitations.isEmpty {
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
                ForEach(invitationsViewModel.teamInvitations) { invitation in
                    invitationRow(invitation)
                }
            }
        }
    }

    private var pendingInvitationsSummary: String {
        let pendingCount = invitationsViewModel.teamInvitations.filter { $0.status == .pending }.count
        if pendingCount > 0 {
            return L10n.format("pendingInvitationsCount", pendingCount)
        }
        return L10n.format("sentInvitations", invitationsViewModel.teamInvitations.count)
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
                        Task { await invitationsViewModel.resendInvitation(invitation) }
                    }
                    Button(L10n.text("cancelInvitation"), role: .destructive) {
                        invitationsViewModel.confirmCancelInvitation(invitation)
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
        .accessibilityElement(children: .combine)
    }
}

#if DEBUG
#Preview {
    TeamInvitationsSection(viewModel: .preview())
        .padding()
        .teamPreviewEnvironment()
}
#endif
