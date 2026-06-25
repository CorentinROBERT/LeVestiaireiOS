//
//  TeamPlayerRowMenu.swift
//  LeVestaire
//

import SwiftUI

struct TeamPlayerRowMenu: View {
    @ObservedObject var viewModel: TeamViewModel
    @ObservedObject var rosterViewModel: TeamRosterViewModel
    let member: TeamMember

    var body: some View {
        menu
            .confirmationDialog(
                L10n.text("supprimerJoueur"),
                isPresented: isRemovalConfirmationPresented,
                titleVisibility: .visible
            ) {
                Button(L10n.text("supprimerJoueur"), role: .destructive) {
                    Task { await rosterViewModel.removeMember(member) }
                }
                Button(L10n.cancel, role: .cancel) {
                    rosterViewModel.memberPendingRemoval = nil
                }
            } message: {
                Text(L10n.format("confirmRemovePlayer", member.displayName))
            }
    }

    private var menu: some View {
        Menu {
            if member.isGuest {
                Button(L10n.text("mergeGuestWithPlayer")) {
                    rosterViewModel.presentMergeGuest(member)
                }
            } else if viewModel.canChangeMemberRoles, member.role != .admin {
                ForEach(TeamRole.assignableMemberRoles) { role in
                    Button(role.localizedLabel) {
                        Task { await rosterViewModel.updateMemberRole(member: member, role: role) }
                    }
                    .disabled(member.role == role)
                }
            }

            Button(L10n.text("supprimerJoueur"), role: .destructive) {
                rosterViewModel.confirmRemoveMember(member)
            }
        } label: {
            Image(systemName: "ellipsis.circle")
                .foregroundStyle(AppPalette.Primary.main)
        }
    }

    private var isRemovalConfirmationPresented: Binding<Bool> {
        Binding(
            get: { rosterViewModel.memberPendingRemoval?.id == member.id },
            set: { _ in }
        )
    }
}
