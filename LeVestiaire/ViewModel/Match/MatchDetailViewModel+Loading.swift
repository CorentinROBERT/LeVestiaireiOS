//
//  MatchDetailViewModel+Loading.swift
//  LeVestaire
//

import Foundation

extension MatchDetailViewModel {
    func loadTabContentIfNeeded(_ tab: MatchDetailTab) async {
        switch tab {
        case .composition:
            await loadSelectablePlayers()
        case .events:
            await loadEventsIfNeeded()
            if canManageMatchEvents {
                await loadEventContext()
            }
        case .statistics:
            await loadMatchStatsIfNeeded()
        case .quiz:
            await loadQuizzesIfNeeded()
        }
    }

    func resetTabCaches() {
        hasLoadedEvents = false
        hasLoadedMatchStats = false
        hasLoadedQuizzes = false
        matchStats = nil
        matchQuizzes = []
    }

    func loadSupplementaryData() async {
        guard let match else { return }

        await resolveTeamManagementAccess()
        if showsAvailabilityManagement {
            try? await loadAvailabilityIfNeeded()
        }

        if match.composition != nil || match.capabilities.canManageComposition {
            await loadCompositionPlayerDirectory()
        }

        if match.composition != nil {
            await loadTeamTemplates()
            enrichCompositionFromTeamTemplatesIfNeeded()
        }

        if match.status == .ongoing || match.status == .finished {
            await loadEventsIfNeeded(force: true)
        }
    }

    func resolveTeamManagementAccess() async {
        guard let match, let teamId = match.teamId, !teamId.isEmpty else {
            canManageMatchTeam = false
            return
        }

        do {
            let teams = try await teamService.fetchUserTeams()
            let team = teams.first { $0.id == teamId }
            canManageMatchTeam = team?.userCanManageTeam(userId: currentUserId) == true
        } catch {
            canManageMatchTeam = false
        }
    }
}
