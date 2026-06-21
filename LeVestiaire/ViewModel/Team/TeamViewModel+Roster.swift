//
//  TeamViewModel+Roster.swift
//  LeVestaire
//

import Foundation

extension TeamViewModel {
    var mergeableTeamMembers: [TeamMember] {
        selectedTeam?.resolvedMembers.filter { member in
            !member.isGuest && !(member.userId ?? member.id).isEmpty
        } ?? []
    }

    func addGuest(
        firstName: String,
        lastName: String?,
        email: String?,
        jerseyNumber: Int?
    ) async -> Bool {
        guard let teamId = selectedTeam?.id else { return false }

        let trimmedFirstName = firstName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedFirstName.isEmpty else {
            showError(L10n.text("firstNameRequired"))
            return false
        }

        if let jerseyNumber, !(1...99).contains(jerseyNumber) {
            showError(L10n.text("jerseyNumberRange"))
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
            await refreshSelectedTeamContent()
            showSuccess(L10n.text("guestAdded"))
            return true
        } catch {
            showError(error.localizedDescription)
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
            showError(L10n.text("pleaseSelectAssociatedPlayer"))
            return false
        }

        isSubmitting = true
        defer { isSubmitting = false }

        do {
            try await teamService.mergeGuest(guestId: guest.id, userId: userId)
            guestPendingMerge = nil
            await refreshSelectedTeamContent()
            showSuccess(L10n.text("guestMerged"))
            return true
        } catch {
            showError(error.localizedDescription)
            return false
        }
    }

    func confirmRemoveMember(_ member: TeamMember) {
        memberPendingRemoval = member
    }

    func removeMember() async {
        guard let member = memberPendingRemoval else { return }
        memberPendingRemoval = nil
        await removeMember(memberId: member.id, isGuest: member.isGuest)
    }

    func removeMember(memberId: String, isGuest: Bool = false) async {
        guard let teamId = selectedTeam?.id else { return }

        let memberIsGuest = isGuest
            || selectedTeam?.resolvedMembers.first(where: { $0.id == memberId })?.isGuest == true

        do {
            if memberIsGuest {
                try await teamService.deleteGuest(guestId: memberId)
            } else {
                try await teamService.removeMember(teamId: teamId, memberId: memberId)
            }
            await refreshSelectedTeamContent()
            showSuccess(L10n.text("successPlayerRemoved"))
        } catch {
            showError(error.localizedDescription)
        }
    }

    func updateMemberRole(member: TeamMember, role: TeamRole) async {
        guard canChangeMemberRoles else { return }
        guard role != .admin else { return }
        guard let teamId = selectedTeam?.id else { return }

        do {
            let updatedTeam = try await teamService.updateMemberRole(
                teamId: teamId,
                memberId: member.roleUpdateUserId,
                role: role
            )
            applyLocalTeamUpdate(updatedTeam)
            showSuccess(L10n.format("roleUpdatedTo", role.localizedLabel))
        } catch {
            showError(error.localizedDescription)
        }
    }

    func transferAdministration(to memberUserId: String) async -> Bool {
        guard canChangeMemberRoles else { return false }
        guard let teamId = selectedTeam?.id else { return false }
        guard !memberUserId.isEmpty else { return false }

        isSubmitting = true
        defer { isSubmitting = false }

        do {
            let updatedTeam = try await teamService.updateMemberRole(
                teamId: teamId,
                memberId: memberUserId,
                role: .admin
            )
            applyLocalTeamUpdate(updatedTeam)
            showSuccess(L10n.text("successTeamUpdated"))
            return true
        } catch {
            showError(error.localizedDescription)
            return false
        }
    }

    func applyLocalTeamUpdate(_ team: SquadTeam) {
        let guests = selectedTeam?.guests ?? team.guests ?? []
        let mergedTeam = team.withGuests(guests)

        selectedTeam = mergedTeam
        if let index = teams.firstIndex(where: { $0.id == team.id }) {
            teams[index] = mergedTeam
        }
    }
}

private extension String {
    var nilIfWhitespace: String? {
        let trimmed = trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }
}
