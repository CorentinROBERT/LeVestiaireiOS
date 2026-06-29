//
//  MatchDetailCompositionViewModel.swift
//  LeVestaire
//

import Combine
import Foundation

@MainActor
final class MatchDetailCompositionViewModel: ObservableObject {
    @Published var selectablePlayers: [MatchSelectablePlayer] = []
    @Published var teamTemplates: [TeamComposition] = []
    @Published var isSavingComposition = false
    @Published var isLockingComposition = false

    private weak var host: MatchDetailViewModel?
    private let matchService: any MatchDetailServicing
    private let compositionService: any CompositionServicing

    init(matchService: any MatchDetailServicing, compositionService: any CompositionServicing) {
        self.matchService = matchService
        self.compositionService = compositionService
    }

    func attach(to host: MatchDetailViewModel) {
        self.host = host
    }

    var canEdit: Bool {
        host?.match?.capabilities.canManageComposition == true
            && host?.match?.isCompositionLocked == false
    }

    func resetCache() {
        selectablePlayers = []
        teamTemplates = []
    }

    func loadSelectablePlayers() async {
        await loadPlayerDirectory()
    }

    func loadSelectablePlayersIfNeeded() async throws {
        await loadPlayerDirectory()
    }

    func loadTeamTemplates() async {
        guard let teamId = host?.match?.teamId else { return }

        do {
            teamTemplates = try await compositionService.fetchTeamCompositions(teamId: teamId)
        } catch {
            teamTemplates = []
        }
    }

    func loadPlayerDirectory() async {
        guard let matchId = host?.matchId else { return }

        do {
            let players = try await matchService.fetchSelectablePlayers(matchId: matchId)
            if !players.isEmpty {
                selectablePlayers = players
                return
            }
        } catch {
            if host?.match?.capabilities.canManageComposition == true {
                surfaceError(error)
            }
        }

        selectablePlayers = await resolveSelectablePlayersFallback()
    }

    func makeCompositionTabDraft() -> CompositionTabDraft {
        makeCompositionTabDrafts().first(where: \.isMain)
            ?? CompositionTabDraft(
                name: host?.match?.title ?? L10n.text("composition"),
                isMain: true
            )
    }

    func makeCompositionTabDrafts() -> [CompositionTabDraft] {
        guard let composition = host?.match?.composition else {
            return [
                CompositionTabDraft(
                    name: host?.match?.title ?? L10n.text("composition"),
                    isMain: true
                )
            ]
        }

        let tabs = CompositionTabDraft.from(composition: composition)
        guard !tabs.isEmpty else {
            return [
                CompositionTabDraft(
                    name: composition.name,
                    formationKey: composition.formation ?? FormationCatalog.defaultFormationKey,
                    isMain: true
                )
            ]
        }
        return tabs
    }

    func save(
        tabs: [CompositionTabDraft],
        templateCompositionId: String? = nil
    ) async -> Bool {
        guard canEdit,
              let matchId = host?.matchId,
              let mainTab = tabs.first(where: \.isMain) else { return false }

        let trimmedName = mainTab.name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty else {
            host?.errorMessage = L10n.text("compositionNameRequired")
            return false
        }

        guard mainTab.starterAssignments.count == 7 else {
            host?.errorMessage = L10n.format(
                "compositionMustHave7StartersCurrently",
                mainTab.starterAssignments.count
            )
            return false
        }

        isSavingComposition = true
        defer { isSavingComposition = false }

        var resolvedMainTab = mainTab
        resolvedMainTab.name = trimmedName

        let request = resolvedMainTab.matchSaveRequest(
            templateCompositionId: templateCompositionId,
            members: host?.editorMembers ?? [],
            alternativeTabs: tabs.filter { !$0.isMain },
            isUpdate: host?.match?.composition != nil
        )

        do {
            let updated: MatchDetail
            if host?.match?.composition != nil {
                updated = try await matchService.updateMatchComposition(matchId: matchId, request: request)
            } else {
                updated = try await matchService.createMatchComposition(matchId: matchId, request: request)
            }
            applyMatchUpdate(updated, templateCompositionId: templateCompositionId)
            await host?.loadSupplementaryData()
            return true
        } catch {
            surfaceError(error)
            return false
        }
    }

    func setCaptain(captainId: String?) async -> Bool {
        guard canEdit, let matchId = host?.matchId else { return false }

        do {
            let updated = try await matchService.updateMatchCompositionCaptain(
                matchId: matchId,
                captainId: captainId
            )
            applyMatchUpdate(updated)
            return true
        } catch {
            surfaceError(error)
            return false
        }
    }

    func lock() async -> Bool {
        guard host?.match?.capabilities.canManageComposition == true,
              let matchId = host?.matchId else { return false }

        isLockingComposition = true
        defer { isLockingComposition = false }

        do {
            let previous = host?.match
            var updated = try await matchService.lockMatchComposition(matchId: matchId)
            if let refreshed = try? await matchService.fetchMatch(id: matchId) {
                updated = refreshed
            }
            if let previous {
                updated = updated.preservingPresentationContext(from: previous)
            }
            host?.match = updated
            await host?.loadSupplementaryData()
            return true
        } catch {
            surfaceError(error)
            return false
        }
    }

    func applyMatchUpdate(_ updated: MatchDetail, templateCompositionId: String? = nil) {
        var resolved = updated
        if let previous = host?.match {
            resolved = updated.preservingPresentationContext(from: previous)
        }
        if let templateCompositionId,
           let template = teamTemplates.first(where: { $0.id == templateCompositionId }),
           let composition = resolved.composition {
            resolved = resolved.replacingComposition(composition.enrichedWithTemplate(template))
        }
        host?.match = resolved
    }

    func alternativeTabs(fromTemplateId templateId: String?) -> [CompositionTabDraft] {
        guard let templateId,
              let template = teamTemplates.first(where: { $0.id == templateId }) else {
            return []
        }
        return CompositionTabDraft.from(composition: template).filter { !$0.isMain }
    }

    func enrichFromTeamTemplatesIfNeeded() {
        guard let composition = host?.match?.composition,
              composition.alternatives.isEmpty,
              !teamTemplates.isEmpty else { return }

        let template = teamTemplates.first { candidate in
            candidate.hasAlternativeFormations
                && (candidate.name == composition.name
                    || candidate.resolvedStarters.count == composition.resolvedStarters.count)
        }

        if let template {
            host?.match = host?.match?.replacingComposition(composition.enrichedWithTemplate(template))
        }
    }

    private func resolveSelectablePlayersFallback() async -> [MatchSelectablePlayer] {
        let availability = host?.availabilityViewModel.availability ?? []
        if !availability.isEmpty {
            return availability.map { $0.asSelectablePlayer() }
        }

        if host?.showsAvailabilityManagement == true || host?.match?.composition != nil,
           let matchId = host?.matchId,
           let roster = try? await matchService.fetchAvailabilityRoster(matchId: matchId) {
            let memberPlayers = roster.members.map { $0.asSelectablePlayer(isGuest: false) }
            let guestPlayers = roster.guests.map { $0.asSelectablePlayer(isGuest: true) }
            return (memberPlayers + guestPlayers).sorted {
                $0.displayName.localizedCaseInsensitiveCompare($1.displayName) == .orderedAscending
            }
        }

        return []
    }

    private func surfaceError(_ error: Error) {
        host?.surfaceError(error)
    }
}
