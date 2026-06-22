//
//  TeamCompositionsViewModel.swift
//  LeVestaire
//

import Combine
import Foundation

@MainActor
final class TeamCompositionsViewModel: ObservableObject {
    @Published var compositions: [TeamComposition] = []
    @Published var compositionsLoadError: String?
    @Published var compositionPendingDeletion: TeamComposition?
    @Published var editingComposition: TeamComposition?
    @Published var isSubmitting = false

    private weak var host: TeamViewModel?
    private let compositionService: CompositionService

    var compositionsLoadedForTeamId: String?

    init(compositionService: CompositionService) {
        self.compositionService = compositionService
    }

    func attach(to host: TeamViewModel) {
        self.host = host
    }

    func resetCache() {
        compositions = []
        compositionsLoadError = nil
        compositionPendingDeletion = nil
        editingComposition = nil
        compositionsLoadedForTeamId = nil
    }

    func invalidateLazyLoads() {
        compositionsLoadedForTeamId = nil
    }

    func loadIfNeeded(force: Bool = false) async {
        guard let teamId = host?.selectedTeamId, !teamId.isEmpty else {
            compositions = []
            compositionsLoadError = nil
            return
        }

        guard force || compositionsLoadedForTeamId != teamId else { return }

        do {
            compositions = try await compositionService.fetchTeamCompositions(teamId: teamId)
            compositionsLoadError = nil
            compositionsLoadedForTeamId = teamId
        } catch {
            compositions = []
            compositionsLoadError = error.localizedDescription
        }
    }

    func retry() async {
        await loadIfNeeded(force: true)
    }

    func confirmDeleteComposition(_ composition: TeamComposition) {
        compositionPendingDeletion = composition
    }

    func deletePendingComposition() async {
        guard let composition = compositionPendingDeletion else { return }
        compositionPendingDeletion = nil
        _ = await delete(composition)
    }

    func openCompositionEditor(for composition: TeamComposition?) {
        editingComposition = composition
        host?.activeSheet = .compositionEditor(composition)
    }

    func save(
        tabs: [CompositionTabDraft],
        deletedAlternativeIds: [String] = []
    ) async -> Bool {
        guard let teamId = host?.selectedTeam?.id else { return false }
        guard let mainTab = tabs.first(where: \.isMain) ?? tabs.first else { return false }

        guard !mainTab.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            host?.showError(L10n.text("compositionNameRequired"))
            return false
        }

        guard mainTab.starterAssignments.count == 7 else {
            host?.showError(
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
                host?.showSuccess(L10n.text("compositionModifiedSuccessfully"))
            } else {
                _ = try await compositionService.createComposition(request)
                host?.showSuccess(L10n.text("compositionCreatedSuccessfully"))
            }
            await loadIfNeeded(force: true)
            return true
        } catch {
            host?.showError(error.localizedDescription)
            return false
        }
    }

    func delete(_ composition: TeamComposition) async -> Bool {
        do {
            try await compositionService.deleteComposition(id: composition.id)
            await loadIfNeeded(force: true)
            host?.showSuccess(L10n.text("compositionDeletedSuccessfully"))
            return true
        } catch {
            host?.showError(error.localizedDescription)
            return false
        }
    }

    func clearLoadErrors() {
        compositionsLoadError = nil
    }

    func prepareForTeamChange() {
        if compositionsLoadedForTeamId != host?.selectedTeamId {
            compositions = []
        }
    }
}
