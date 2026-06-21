//
//  TeamViewModel+Compositions.swift
//  LeVestaire
//

import Foundation

extension TeamViewModel {
    func confirmDeleteComposition(_ composition: TeamComposition) {
        compositionPendingDeletion = composition
    }

    func deletePendingComposition() async {
        guard let composition = compositionPendingDeletion else { return }
        compositionPendingDeletion = nil
        _ = await deleteComposition(composition)
    }

    func openCompositionEditor(for composition: TeamComposition?) {
        editingComposition = composition
        activeSheet = .compositionEditor(composition)
    }

    func saveComposition(
        tabs: [CompositionTabDraft],
        deletedAlternativeIds: [String] = []
    ) async -> Bool {
        guard let teamId = selectedTeam?.id else { return false }
        guard let mainTab = tabs.first(where: \.isMain) ?? tabs.first else { return false }

        guard !mainTab.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            showError(L10n.text("compositionNameRequired"))
            return false
        }

        guard mainTab.starterAssignments.count == 7 else {
            showError(
                L10n.format(
                    "compositionMustHave7StartersCurrently",
                    mainTab.starterAssignments.count
                )
            )
            return false
        }

        isSubmitting = true
        defer { isSubmitting = false }

        let alternativeTabs = tabs.filter { !$0.isMain }
        let request = mainTab.teamSaveRequest(
            teamId: teamId,
            alternativeTabs: alternativeTabs
        )

        do {
            if let compositionId = editingComposition?.id {
                for alternativeId in deletedAlternativeIds {
                    try await compositionService.deleteAlternativeFormation(
                        compositionId: compositionId,
                        alternativeId: alternativeId
                    )
                }
                _ = try await compositionService.updateComposition(id: compositionId, request: request)
                showSuccess(L10n.text("compositionModifiedSuccessfully"))
            } else {
                _ = try await compositionService.createComposition(request)
                showSuccess(L10n.text("compositionCreatedSuccessfully"))
            }
            await loadCompositions()
            compositionsLoadedForTeamId = selectedTeamId
            return true
        } catch {
            showError(error.localizedDescription)
            return false
        }
    }

    func deleteComposition(_ composition: TeamComposition) async -> Bool {
        do {
            try await compositionService.deleteComposition(id: composition.id)
            await loadCompositions()
            compositionsLoadedForTeamId = selectedTeamId
            showSuccess(L10n.text("compositionDeletedSuccessfully"))
            return true
        } catch {
            showError(error.localizedDescription)
            return false
        }
    }
}
