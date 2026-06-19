//
//  TeamPlayersSection.swift
//  LeVestaire
//

import SwiftUI

struct TeamPlayersSection: View {
    @ObservedObject var viewModel: TeamViewModel

    var body: some View {
        UCard(title: L10n.text("players"), icon: "person.2.fill") {
            if viewModel.isRefreshingTeam, (viewModel.selectedTeam?.resolvedMembers ?? []).isEmpty {
                TeamLoadingPlaceholder()
            } else if (viewModel.selectedTeam?.resolvedMembers ?? []).isEmpty {
                TeamEmptyState(
                    icon: "person.2",
                    title: L10n.text("emptyPlayersTitle"),
                    message: L10n.text("emptyPlayersMessage")
                )
            } else {
                VStack(spacing: 12) {
                    ForEach(viewModel.selectedTeam?.resolvedMembers ?? []) { member in
                        playerRow(member)
                    }
                }
            }
        }
    }

    @ViewBuilder
    private func playerRow(_ member: TeamMember) -> some View {
        HStack(spacing: 12) {
            if let jerseyNumber = member.jerseyNumber {
                TeamJerseyBadge(number: jerseyNumber)
            } else {
                TeamMemberAvatar(initials: member.initials)
            }

            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Text(member.displayName)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(AppPalette.Neutral.textPrimary)

                    if member.isGuest {
                        TeamGuestBadge()
                    }
                }

                if let role = member.role {
                    TeamRoleBadge(role: role)
                } else {
                    Text(L10n.text("player"))
                        .font(.caption)
                        .foregroundStyle(AppPalette.Neutral.textSecondary)
                }
            }

            Spacer()

            if viewModel.canManageTeam {
                Menu {
                    if !member.isGuest {
                        ForEach(TeamRole.allCases) { role in
                            Button(role.localizedLabel) {
                                Task { await viewModel.updateMemberRole(memberId: member.id, role: role) }
                            }
                        }
                    }
                    Button(L10n.text("supprimerJoueur"), role: .destructive) {
                        viewModel.confirmRemoveMember(member)
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                        .foregroundStyle(AppPalette.Primary.main)
                }
            }
        }
        .padding(12)
        .glassEffect(.regular, in: .rect(cornerRadius: 14))
        .overlay {
            RoundedRectangle(cornerRadius: 14)
                .stroke(TeamRoleStyle.color(for: member.role).opacity(0.18), lineWidth: 1)
        }
    }
}
