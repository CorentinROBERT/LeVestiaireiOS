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

    @Published var isLoading = false
    @Published var isRefreshingTeam = false
    @Published var isSubmitting = false

    @Published var activeSheet: TeamSheet?
    @Published var alertMessage: String?
    @Published var toastMessage: String?
    @Published var errorMessage: String?

    let pullToRefreshTask = PullToRefreshTask()

    let teamService: TeamService
    let compositionService: CompositionService
    let statsService: StatsService
    let selectedTeamStore: SelectedTeamStore
    let authService: AuthService

    let statsViewModel: TeamStatsViewModel
    let invitationsViewModel: TeamInvitationsViewModel
    let compositionsViewModel: TeamCompositionsViewModel
    let rosterViewModel: TeamRosterViewModel

    init(
        teamService: TeamService,
        compositionService: CompositionService,
        statsService: StatsService,
        selectedTeamStore: SelectedTeamStore,
        authService: AuthService,
        statsViewModel: TeamStatsViewModel? = nil,
        invitationsViewModel: TeamInvitationsViewModel? = nil,
        compositionsViewModel: TeamCompositionsViewModel? = nil,
        rosterViewModel: TeamRosterViewModel? = nil
    ) {
        self.teamService = teamService
        self.compositionService = compositionService
        self.statsService = statsService
        self.selectedTeamStore = selectedTeamStore
        self.authService = authService
        self.statsViewModel = statsViewModel ?? TeamStatsViewModel(statsService: statsService)
        self.invitationsViewModel = invitationsViewModel ?? TeamInvitationsViewModel(teamService: teamService)
        self.compositionsViewModel = compositionsViewModel ?? TeamCompositionsViewModel(
            compositionService: compositionService
        )
        self.rosterViewModel = rosterViewModel ?? TeamRosterViewModel(teamService: teamService)
        self.statsViewModel.attach(to: self)
        self.invitationsViewModel.attach(to: self)
        self.compositionsViewModel.attach(to: self)
        self.rosterViewModel.attach(to: self)
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

    var canChangeMemberRoles: Bool {
        currentUserRole?.canChangeMemberRoles == true
    }

    var kpiMemberCountDisplay: String {
        "\(selectedTeam?.resolvedMemberCount ?? 0)"
    }

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

    func applyLocalTeamUpdate(_ team: SquadTeam) {
        let guests = selectedTeam?.guests ?? team.guests ?? []
        let mergedTeam = team.withGuests(guests)

        selectedTeam = mergedTeam
        if let index = teams.firstIndex(where: { $0.id == team.id }) {
            teams[index] = mergedTeam
        }
    }
}
