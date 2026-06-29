//
//  TeamRosterViewModel.swift
//  LeVestaire
//

import Combine
import Foundation

@MainActor
final class TeamRosterViewModel: ObservableObject {
    @Published var memberPendingRemoval: TeamMember?
    @Published var guestPendingMerge: TeamMember?
    @Published var isSubmitting = false

    private weak var host: TeamViewModel?
    private let teamService: any TeamManagementServicing

    init(teamService: any TeamManagementServicing) {
        self.teamService = teamService
    }

    func attach(to host: TeamViewModel) {
        self.host = host
    }

    var mergeableTeamMembers: [TeamMember] {
        host?.selectedTeam?.resolvedMembers.filter { member in
            !member.isGuest && !(member.userId ?? member.id).isEmpty
        } ?? []
    }

    func addGuest(
        firstName: String,
        lastName: String?,
        email: String?,
        jerseyNumber: Int?
    ) async -> Bool {
        guard let teamId = host?.selectedTeam?.id else { return false }

        let trimmedFirstName = firstName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedFirstName.isEmpty else {
            host?.showError(L10n.text("firstNameRequired"))
            return false
        }

        if let jerseyNumber, !(1...99).contains(jerseyNumber) {
            host?.showError(L10n.text("jerseyNumberRange"))
            return false
        }

        isSubmitting = true
        defer { isSubmitting = false }

        do {
            try await teamService.addGuest(
                teamId: teamId,
                request: CreateGuestRequest(
                    firstName: trimmedFirstName,
                    lastName: lastName?.nilIfWhitespace,
                    email: email?.nilIfWhitespace,
                    jerseyNumber: jerseyNumber,
                    notes: nil
                )
            )
            await host?.refreshSelectedTeamContent()
            host?.showSuccess(L10n.text("guestAdded"))
            return true
        } catch {
            host?.showError(error.localizedDescription)
            return false
        }
    }

    func presentMergeGuest(_ guest: TeamMember) {
        guestPendingMerge = guest
    }

    func mergeGuest(with member: TeamMember) async -> Bool {
        guard let guest = guestPendingMerge, guest.isGuest else { return false }

        let userId = member.userId ?? member.id
        guard !userId.isEmpty else {
            host?.showError(L10n.text("pleaseSelectAssociatedPlayer"))
            return false
        }

        isSubmitting = true
        defer { isSubmitting = false }

        do {
            try await teamService.mergeGuest(guestId: guest.id, userId: userId)
            guestPendingMerge = nil
            await host?.refreshSelectedTeamContent()
            host?.showSuccess(L10n.text("guestMerged"))
            return true
        } catch {
            host?.showError(error.localizedDescription)
            return false
        }
    }

    func confirmRemoveMember(_ member: TeamMember) {
        memberPendingRemoval = member
    }

    func removeMember(_ member: TeamMember) async {
        let memberId = member.isGuest ? member.id : member.roleUpdateUserId
        guard !memberId.isEmpty else { return }
        guard let teamId = host?.selectedTeam?.id else { return }

        memberPendingRemoval = nil

        do {
            if member.isGuest {
                try await teamService.deleteGuest(guestId: memberId)
            } else {
                try await teamService.removeMember(teamId: teamId, memberId: memberId)
            }
            await host?.refreshSelectedTeamContent()
            host?.showSuccess(L10n.text("successPlayerRemoved"))
        } catch {
            host?.showError(error.localizedDescription)
        }
    }

    func updateMemberRole(member: TeamMember, role: TeamRole) async {
        guard host?.canChangeMemberRoles == true else { return }
        guard role != .admin else { return }
        guard let teamId = host?.selectedTeam?.id else { return }

        do {
            let updatedTeam = try await teamService.updateMemberRole(
                teamId: teamId,
                memberId: member.roleUpdateUserId,
                role: role
            )
            host?.applyLocalTeamUpdate(updatedTeam)
            host?.showSuccess(L10n.format("roleUpdatedTo", role.localizedLabel))
        } catch {
            host?.showError(error.localizedDescription)
        }
    }

    func transferAdministration(to memberUserId: String) async -> Bool {
        guard host?.canChangeMemberRoles == true else { return false }
        guard let teamId = host?.selectedTeam?.id else { return false }
        guard !memberUserId.isEmpty else { return false }

        isSubmitting = true
        defer { isSubmitting = false }

        do {
            let updatedTeam = try await teamService.updateMemberRole(
                teamId: teamId,
                memberId: memberUserId,
                role: .admin
            )
            host?.applyLocalTeamUpdate(updatedTeam)
            host?.showSuccess(L10n.text("successTeamUpdated"))
            return true
        } catch {
            host?.showError(error.localizedDescription)
            return false
        }
    }
}

private extension String {
    var nilIfWhitespace: String? {
        let trimmed = trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }
}
