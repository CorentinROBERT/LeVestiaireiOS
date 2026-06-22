//
//  MatchDetailViewModel+Loading.swift
//  LeVestaire
//

import Foundation

extension MatchDetailViewModel {
    func loadTabContentIfNeeded(_ tab: MatchDetailTab) async {
        switch tab {
        case .composition:
            await compositionViewModel.loadSelectablePlayers()
        case .events:
            await eventsViewModel.loadIfNeeded()
            if eventsViewModel.canManage {
                await eventsViewModel.loadContext()
            }
        case .statistics:
            await statisticsViewModel.loadIfNeeded()
        case .quiz:
            await quizViewModel.loadIfNeeded()
        }
    }

    func reloadAllTabContent(force: Bool = false) async {
        guard let match else { return }

        if match.status == .ongoing || match.status == .finished {
            await eventsViewModel.loadIfNeeded(force: force)
            if eventsViewModel.canManage {
                await eventsViewModel.loadContext()
            }
            await statisticsViewModel.loadIfNeeded(force: force)
        }

        if match.status == .finished {
            await quizViewModel.loadIfNeeded(force: force)
        }
    }

    func reloadPreparationContent(force: Bool = false) async {
        guard let match, match.showsPrepareHub else { return }

        if force {
            availabilityViewModel.availabilityBoardSummary = match.availabilitySummary
            await availabilityViewModel.refreshBoard(force: true)
        } else if showsAvailabilityManagement {
            await availabilityViewModel.loadIfNeeded()
        }

        if match.composition != nil || match.capabilities.canManageComposition {
            await compositionViewModel.loadPlayerDirectory()
        }

        if match.capabilities.canManageComposition {
            await compositionViewModel.loadTeamTemplates()
        }

        if match.composition != nil {
            compositionViewModel.enrichFromTeamTemplatesIfNeeded()
        }
    }

    func resetTabCaches() {
        availabilityViewModel.resetCache()
        compositionViewModel.resetCache()
        statisticsViewModel.resetCache()
        eventsViewModel.resetCache()
        quizViewModel.resetCache()
    }

    func loadSupplementaryData() async {
        guard let match else { return }

        if match.showsPrepareHub {
            await reloadPreparationContent(force: true)
            return
        }

        if match.composition != nil || match.capabilities.canManageComposition {
            await compositionViewModel.loadPlayerDirectory()
        }

        if match.capabilities.canManageComposition {
            await compositionViewModel.loadTeamTemplates()
        }

        if match.composition != nil {
            compositionViewModel.enrichFromTeamTemplatesIfNeeded()
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
