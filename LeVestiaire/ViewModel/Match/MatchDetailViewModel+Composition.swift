//
//  MatchDetailViewModel+Composition.swift
//  LeVestaire
//

import Foundation

extension MatchDetailViewModel {
    func loadSelectablePlayers() async {
        await loadCompositionPlayerDirectory()
    }

    func loadSelectablePlayersIfNeeded() async throws {
        await loadCompositionPlayerDirectory()
    }

    func resolveSelectablePlayersFallback() async -> [MatchSelectablePlayer] {
        if !availability.isEmpty {
            return availability.map { $0.asSelectablePlayer() }
        }

        if showsAvailabilityManagement || match?.composition != nil {
            if let roster = try? await matchService.fetchAvailabilityRoster(matchId: matchId) {
                let memberPlayers = roster.members.map { $0.asSelectablePlayer(isGuest: false) }
                let guestPlayers = roster.guests.map { $0.asSelectablePlayer(isGuest: true) }
                return (memberPlayers + guestPlayers).sorted {
                    $0.displayName.localizedCaseInsensitiveCompare($1.displayName) == .orderedAscending
                }
            }
        }

        return []
    }

    func loadTeamTemplates() async {
        guard let teamId = match?.teamId else { return }

        do {
            teamTemplates = try await compositionService.fetchTeamCompositions(teamId: teamId)
        } catch {
            teamTemplates = []
        }
    }

    func makeCompositionTabDraft() -> CompositionTabDraft {
        makeCompositionTabDrafts().first(where: \.isMain)
            ?? CompositionTabDraft(
                name: match?.title ?? L10n.text("composition"),
                isMain: true
            )
    }

    func makeCompositionTabDrafts() -> [CompositionTabDraft] {
        guard let composition = match?.composition else {
            return [
                CompositionTabDraft(
                    name: match?.title ?? L10n.text("composition"),
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

    func saveMatchComposition(
        tabs: [CompositionTabDraft],
        templateCompositionId: String? = nil
    ) async -> Bool {
        guard canEditComposition else { return false }
        guard let mainTab = tabs.first(where: \.isMain) else { return false }

        let trimmedName = mainTab.name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty else {
            errorMessage = L10n.text("compositionNameRequired")
            return false
        }

        guard mainTab.starterAssignments.count == 7 else {
            errorMessage = L10n.format(
                "compositionMustHave7StartersCurrently",
                mainTab.starterAssignments.count
            )
            return false
        }

        isSavingComposition = true
        errorMessage = nil
        defer { isSavingComposition = false }

        var resolvedMainTab = mainTab
        resolvedMainTab.name = trimmedName

        let request = resolvedMainTab.matchSaveRequest(
            templateCompositionId: templateCompositionId,
            members: editorMembers,
            alternativeTabs: tabs.filter { !$0.isMain }
        )

        do {
            let updated: MatchDetail
            if match?.composition != nil {
                updated = try await matchService.updateMatchComposition(matchId: matchId, request: request)
            } else {
                updated = try await matchService.createMatchComposition(matchId: matchId, request: request)
            }
            applyMatchUpdate(updated, templateCompositionId: templateCompositionId)
            await loadSupplementaryData()
            return true
        } catch {
            surfaceError(error)
            return false
        }
    }

    func lockComposition() async -> Bool {
        guard match?.capabilities.canManageComposition == true else { return false }

        isLockingComposition = true
        errorMessage = nil
        defer { isLockingComposition = false }

        do {
            let previous = match
            var updated = try await matchService.lockMatchComposition(matchId: matchId)
            if let refreshed = try? await matchService.fetchMatch(id: matchId) {
                updated = refreshed
            }
            if let previous {
                updated = updated.preservingPresentationContext(from: previous)
            }
            match = updated
            await loadSupplementaryData()
            return true
        } catch {
            surfaceError(error)
            return false
        }
    }

    func applyMatchUpdate(_ updated: MatchDetail, templateCompositionId: String? = nil) {
        var resolved = updated
        if let previous = match {
            resolved = updated.preservingPresentationContext(from: previous)
        }
        if let templateCompositionId,
           let template = teamTemplates.first(where: { $0.id == templateCompositionId }),
           let composition = resolved.composition {
            resolved = resolved.replacingComposition(composition.enrichedWithTemplate(template))
        }
        match = resolved
    }

    func alternativeTabs(fromTemplateId templateId: String?) -> [CompositionTabDraft] {
        guard let templateId,
              let template = teamTemplates.first(where: { $0.id == templateId }) else {
            return []
        }
        return CompositionTabDraft.from(composition: template).filter { !$0.isMain }
    }

    func enrichCompositionFromTeamTemplatesIfNeeded() {
        guard let composition = match?.composition,
              composition.alternatives.isEmpty,
              !teamTemplates.isEmpty else { return }

        let template = teamTemplates.first { candidate in
            candidate.hasAlternativeFormations
                && (candidate.name == composition.name
                    || candidate.resolvedStarters.count == composition.resolvedStarters.count)
        }

        if let template {
            match = match?.replacingComposition(composition.enrichedWithTemplate(template))
        }
    }

    func loadCompositionPlayerDirectory() async {
        do {
            let players = try await matchService.fetchSelectablePlayers(matchId: matchId)
            if !players.isEmpty {
                selectablePlayers = players
                return
            }
        } catch {
            if match?.capabilities.canManageComposition == true {
                surfaceError(error)
            }
        }

        selectablePlayers = await resolveSelectablePlayersFallback()
    }
}
