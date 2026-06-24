//
//  TeamViewModel+TeamInvite.swift
//  LeVestaire
//

import Foundation

extension TeamViewModel {
    func loadTeamInviteLink() async {
        guard canManageTeam, !selectedTeamId.isEmpty else { return }

        teamInviteLinkError = nil
        isLoadingTeamInviteLink = true
        defer { isLoadingTeamInviteLink = false }

        do {
            teamInviteLink = try await teamService.fetchTeamInviteLink(teamId: selectedTeamId)
        } catch {
            teamInviteLink = nil
            teamInviteLinkError = error.localizedDescription
        }
    }

    func regenerateTeamInviteLink() async {
        guard canManageTeam, !selectedTeamId.isEmpty else { return }

        teamInviteLinkError = nil
        isLoadingTeamInviteLink = true
        defer { isLoadingTeamInviteLink = false }

        do {
            teamInviteLink = try await teamService.regenerateTeamInviteLink(teamId: selectedTeamId)
            showSuccess(L10n.text("teamInviteRegenerated"))
        } catch {
            teamInviteLinkError = error.localizedDescription
        }
    }

    func presentShareTeamInviteSheet() {
        activeSheet = .shareTeamInvite
    }
}
