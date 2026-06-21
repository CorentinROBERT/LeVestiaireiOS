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

    func reloadAllTabContent(force: Bool = false) async {
        guard let match else { return }

        if match.status == .ongoing || match.status == .finished {
            await loadEventsIfNeeded(force: force)
            if canManageMatchEvents {
                await loadEventContext()
            }
            await loadMatchStatsIfNeeded(force: force)
        }

        if match.status == .finished {
            await loadQuizzesIfNeeded(force: force)
        }
    }

    func reloadPreparationContent(force: Bool = false) async {
        guard let match, match.showsPrepareHub else { return }

        if force {
            availabilityBoardSummary = match.availabilitySummary
            await refreshAvailabilityBoard(force: true)
        } else if showsAvailabilityManagement {
            await loadAvailabilityIfNeeded()
        }

        if match.composition != nil || match.capabilities.canManageComposition {
            await loadCompositionPlayerDirectory()
        }

        if match.composition != nil {
            await loadTeamTemplates()
            enrichCompositionFromTeamTemplatesIfNeeded()
        }
    }

    func resetTabCaches() {
        hasLoadedEvents = false
        hasLoadedMatchStats = false
        hasLoadedQuizzes = false
        hasLoadedAvailability = false
        events = []
        availability = []
        availabilityBoardSummary = nil
        matchStats = nil
        matchQuizzes = []
        activeQuizDetail = nil
        quizUserSubmission = nil
        quizLeaderboard = []
        quizLeaderboardCounts = nil
        quizSubmitFeedback = nil
        selectedQuizId = nil
        quizTeamMembers = []
    }

    func loadSupplementaryData() async {
        guard let match else { return }

        if match.showsPrepareHub {
            await reloadPreparationContent(force: true)
            return
        }

        if match.composition != nil || match.capabilities.canManageComposition {
            await loadCompositionPlayerDirectory()
        }

        if match.composition != nil {
            await loadTeamTemplates()
            enrichCompositionFromTeamTemplatesIfNeeded()
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
