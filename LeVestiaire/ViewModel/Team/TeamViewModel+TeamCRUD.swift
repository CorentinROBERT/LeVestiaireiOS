//
//  TeamViewModel+TeamCRUD.swift
//  LeVestaire
//

import UIKit

extension TeamViewModel {
    func createTeam(name: String, description: String?, logo: UIImage?) async -> Bool {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmedName.count >= 2 else {
            showError(L10n.text("teamNameMinLength"))
            return false
        }

        isSubmitting = true
        defer { isSubmitting = false }

        do {
            let team = try await teamService.createTeam(
                name: trimmedName,
                description: description?.nilIfWhitespace,
                logo: logo
            )
            teams.append(team)
            selectedTeamId = team.id
            selectedTeamStore.selectedTeamId = team.id
            await refreshSelectedTeamContent()
            showSuccess(L10n.format("teamCreatedSuccessfully", team.name))
            return true
        } catch {
            showError(error.localizedDescription)
            return false
        }
    }

    func updateTeam(name: String, description: String?, logo: UIImage?) async -> Bool {
        guard let teamId = selectedTeam?.id else { return false }

        isSubmitting = true
        defer { isSubmitting = false }

        do {
            let team = try await teamService.updateTeam(
                id: teamId,
                name: name.nilIfWhitespace,
                description: description?.nilIfWhitespace,
                logo: logo
            )
            replaceTeam(team)
            showSuccess(L10n.text("successTeamUpdated"))
            return true
        } catch {
            showError(error.localizedDescription)
            return false
        }
    }

    func deleteSelectedTeam() async -> Bool {
        guard let teamId = selectedTeam?.id else { return false }

        isSubmitting = true
        defer { isSubmitting = false }

        do {
            try await teamService.deleteTeam(id: teamId)
            teams.removeAll { $0.id == teamId }
            restoreSelection()
            await refreshSelectedTeamContent()
            showSuccess(L10n.text("teamDeletedSuccessfully"))
            return true
        } catch {
            showError(error.localizedDescription)
            return false
        }
    }

    func leaveSelectedTeam() async -> Bool {
        guard let teamId = selectedTeam?.id else { return false }

        isSubmitting = true
        defer { isSubmitting = false }

        do {
            try await teamService.leaveTeam(id: teamId)
            teams.removeAll { $0.id == teamId }
            restoreSelection()
            await refreshSelectedTeamContent()
            showSuccess(L10n.text("quitterEquipeSucces"))
            return true
        } catch {
            showError(error.localizedDescription)
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
