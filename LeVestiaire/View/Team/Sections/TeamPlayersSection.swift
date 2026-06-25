//
//  TeamPlayersSection.swift
//  LeVestaire
//

import SwiftUI

struct TeamPlayersSection: View {
    @ObservedObject var viewModel: TeamViewModel
    @ObservedObject var rosterViewModel: TeamRosterViewModel

    init(viewModel: TeamViewModel) {
        self.viewModel = viewModel
        self.rosterViewModel = viewModel.rosterViewModel
    }

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

                if member.role == .admin || member.role == .manager, let role = member.role {
                    TeamRoleBadge(role: role)
                } else {
                    Text(L10n.text("player"))
                        .font(.caption)
                        .foregroundStyle(AppPalette.Neutral.textSecondary)
                }
            }

            Spacer()

            if viewModel.canManageTeam {
                TeamPlayerRowMenu(
                    viewModel: viewModel,
                    rosterViewModel: rosterViewModel,
                    member: member
                )
            }
        }
        .padding(12)
        .glassEffect(.regular, in: .rect(cornerRadius: 14))
        .overlay {
            RoundedRectangle(cornerRadius: 14)
                .stroke(TeamRoleStyle.color(for: member.role).opacity(0.18), lineWidth: 1)
        }
        .accessibilityElement(children: .combine)
    }
}

#if DEBUG
#Preview {
    ScrollView {
        TeamPlayersSection(viewModel: .preview())
            .padding()
    }
    .teamPreviewEnvironment()
}
#endif
