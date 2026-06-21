//
//  TeamViewModel+Invitations.swift
//  LeVestaire
//

import Foundation

extension TeamViewModel {
    func invitePlayer(email: String, firstName: String, lastName: String?) async -> Bool {
        guard let teamId = selectedTeam?.id else { return false }

        let trimmedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedFirstName = firstName.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !trimmedEmail.isEmpty else {
            showError(L10n.text("enterEmail"))
            return false
        }

        guard !trimmedFirstName.isEmpty else {
            showError(L10n.text("firstNameRequired"))
            return false
        }

        isSubmitting = true
        defer { isSubmitting = false }

        do {
            try await teamService.invitePlayer(
                teamId: teamId,
                email: trimmedEmail,
                firstName: trimmedFirstName,
                lastName: lastName?.nilIfWhitespace
            )
            await loadTeamInvitations()
            showSuccess(L10n.text("invitationSentSuccessfully"))
            return true
        } catch {
            showError(error.localizedDescription)
            return false
        }
    }

    func resendInvitation(_ invitation: TeamInvitation) async {
        guard invitation.status.canManage else { return }

        do {
            try await teamService.resendInvitation(invitationId: invitation.id)
            await loadTeamInvitations()
            showSuccess(L10n.text("invitationResent"))
        } catch {
            showError(error.localizedDescription)
        }
    }

    func confirmCancelInvitation(_ invitation: TeamInvitation) {
        invitationPendingCancellation = invitation
    }

    func cancelInvitation() async {
        guard let invitation = invitationPendingCancellation else { return }
        invitationPendingCancellation = nil

        do {
            try await teamService.cancelInvitation(invitationId: invitation.id)
            await loadTeamInvitations()
            showSuccess(L10n.text("invitationCancelled"))
        } catch {
            showError(error.localizedDescription)
        }
    }

    func presentInvitePlayerSheet() {
        activeSheet = .invitePlayer
    }
}

private extension String {
    var nilIfWhitespace: String? {
        let trimmed = trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }
}
