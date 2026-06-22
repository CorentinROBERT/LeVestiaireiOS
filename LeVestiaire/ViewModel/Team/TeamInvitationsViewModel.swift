//
//  TeamInvitationsViewModel.swift
//  LeVestaire
//

import Combine
import Foundation

@MainActor
final class TeamInvitationsViewModel: ObservableObject {
    @Published var teamInvitations: [TeamInvitation] = []
    @Published var isLoadingInvitations = false
    @Published var invitationsLoadError: String?
    @Published var invitationPendingCancellation: TeamInvitation?
    @Published var isSubmitting = false

    private weak var host: TeamViewModel?
    private let teamService: TeamService

    init(teamService: TeamService) {
        self.teamService = teamService
    }

    func attach(to host: TeamViewModel) {
        self.host = host
    }

    func resetCache() {
        teamInvitations = []
        invitationsLoadError = nil
        invitationPendingCancellation = nil
    }

    func loadIfNeeded() async {
        guard host?.canManageTeam == true,
              let teamId = host?.selectedTeamId,
              !teamId.isEmpty else {
            teamInvitations = []
            invitationsLoadError = nil
            return
        }

        isLoadingInvitations = true
        defer { isLoadingInvitations = false }

        do {
            teamInvitations = try await teamService.fetchTeamInvitations(teamId: teamId)
            invitationsLoadError = nil
        } catch {
            teamInvitations = []
            invitationsLoadError = error.localizedDescription
        }
    }

    func retry() async {
        await loadIfNeeded()
    }

    func invitePlayer(email: String, firstName: String, lastName: String?) async -> Bool {
        guard let teamId = host?.selectedTeam?.id else { return false }

        let trimmedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedFirstName = firstName.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !trimmedEmail.isEmpty else {
            host?.showError(L10n.text("enterEmail"))
            return false
        }

        guard !trimmedFirstName.isEmpty else {
            host?.showError(L10n.text("firstNameRequired"))
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
            await loadIfNeeded()
            host?.showSuccess(L10n.text("invitationSentSuccessfully"))
            return true
        } catch {
            host?.showError(error.localizedDescription)
            return false
        }
    }

    func resendInvitation(_ invitation: TeamInvitation) async {
        guard invitation.status.canManage else { return }

        do {
            try await teamService.resendInvitation(invitationId: invitation.id)
            await loadIfNeeded()
            host?.showSuccess(L10n.text("invitationResent"))
        } catch {
            host?.showError(error.localizedDescription)
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
            await loadIfNeeded()
            host?.showSuccess(L10n.text("invitationCancelled"))
        } catch {
            host?.showError(error.localizedDescription)
        }
    }

    func presentInvitePlayerSheet() {
        host?.activeSheet = .invitePlayer
    }

    func clearLoadErrors() {
        invitationsLoadError = nil
    }
}

private extension String {
    var nilIfWhitespace: String? {
        let trimmed = trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }
}
