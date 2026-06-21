//
//  TeamViewModel.swift
//  LeVestaire
//

import Combine
import Foundation
import UIKit

@MainActor
final class TeamViewModel: ObservableObject {
    @Published var teams: [SquadTeam] = []
    @Published var selectedTeamId: String = ""
    @Published var selectedTeam: SquadTeam?
    @Published var compositions: [TeamComposition] = []
    @Published var teamSeasonStats: TeamSeasonStatsPayload?
    @Published var teamRankings: TeamSeasonRankings?
    @Published var teamInvitations: [TeamInvitation] = []
    @Published var availableSeasons: [String] = []
    @Published var selectedStatsSeason = ""
    @Published var selectedRankingSeason = ""
    @Published var selectedRankingKind: TeamRankingKind = .scorers

    @Published var isLoading = false
    @Published var isRefreshingTeam = false
    @Published var isLoadingStats = false
    @Published var isLoadingRankings = false
    @Published var isLoadingInvitations = false
    @Published var isSubmitting = false

    @Published var invitationPendingCancellation: TeamInvitation?
    @Published var memberPendingRemoval: TeamMember?
    @Published var guestPendingMerge: TeamMember?
    @Published var compositionPendingDeletion: TeamComposition?

    @Published var compositionsLoadError: String?
    @Published var invitationsLoadError: String?
    @Published var statsLoadError: String?
    @Published var rankingsLoadError: String?

    @Published var activeSheet: TeamSheet?
    @Published var editingComposition: TeamComposition?
    @Published var alertMessage: String?
    @Published var toastMessage: String?
    @Published var errorMessage: String?

    var seasonsTeamId: String?
    var statsLoadedForTeamId: String?
    var rankingsLoadedForTeamId: String?
    var compositionsLoadedForTeamId: String?

    let teamService: TeamService
    let compositionService: CompositionService
    let statsService: StatsService
    let selectedTeamStore: SelectedTeamStore
    let authService: AuthService

    init(
        teamService: TeamService,
        compositionService: CompositionService,
        statsService: StatsService,
        selectedTeamStore: SelectedTeamStore,
        authService: AuthService
    ) {
        self.teamService = teamService
        self.compositionService = compositionService
        self.statsService = statsService
        self.selectedTeamStore = selectedTeamStore
        self.authService = authService
    }

    convenience init() {
        self.init(
            teamService: .shared,
            compositionService: .shared,
            statsService: .shared,
            selectedTeamStore: .shared,
            authService: .shared
        )
    }

    var hasTeams: Bool { !teams.isEmpty }

    var currentUserRole: TeamRole? {
        selectedTeam?.resolvedCurrentUserRole(userId: authService.currentUser?.id)
    }

    var canManageTeam: Bool {
        currentUserRole?.canManageTeam == true
    }

    var statsKPIsUnavailable: Bool {
        TeamKPIDisplay.statsUnavailable(
            stats: teamSeasonStats,
            hasError: statsLoadError != nil,
            isLoading: isLoadingStats
        )
    }

    var kpiMatchesPlayedDisplay: String {
        TeamKPIDisplay.matchesPlayed(
            stats: teamSeasonStats,
            hasError: statsLoadError != nil,
            isLoading: isLoadingStats
        )
    }

    var kpiGoalsDisplay: String {
        TeamKPIDisplay.goals(
            stats: teamSeasonStats,
            hasError: statsLoadError != nil,
            isLoading: isLoadingStats
        )
    }

    var kpiAssistsDisplay: String {
        TeamKPIDisplay.assists(
            stats: teamSeasonStats,
            hasError: statsLoadError != nil,
            isLoading: isLoadingStats
        )
    }

    var kpiMemberCountDisplay: String {
        "\(selectedTeam?.resolvedMemberCount ?? 0)"
    }

    var isLoadingKPIs: Bool { isLoadingStats && teamSeasonStats == nil }

    var showsTeamDetailError: Bool {
        hasTeams && selectedTeam == nil && errorMessage != nil
    }

    func showSuccess(_ message: String) {
        toastMessage = message
        TeamHaptics.success()
    }

    func showError(_ message: String) {
        alertMessage = message
    }
}

private extension String {
    var nilIfWhitespace: String? {
        let trimmed = trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }
}
