//
//  TeamTestSupport.swift
//  LeVestiaireTests
//

import Foundation
@testable import LeVestiaire

@MainActor
enum TeamTestSupport {
  static func makeHost(
    team: SquadTeam? = nil,
    teamService: (any TeamManagementServicing)? = nil,
    hostTeamService: MockTeamHostService? = nil,
    compositionService: MockCompositionService? = nil,
    statsService: MockStatsService? = nil,
    auth: MockAuthService? = nil
  ) -> TeamViewModel {
    let resolvedTeam = team ?? ViewModelTestFixtures.managedTeam
    let hostService = hostTeamService ?? MockTeamHostService()
    let managementService = teamService ?? hostService
    let compositionService = compositionService ?? MockCompositionService()
    let statsService = statsService ?? MockStatsService()
    let auth = auth ?? MockAuthService()
    auth.currentUser = ViewModelTestFixtures.user

    let viewModel = TeamViewModel(
      teamService: hostService,
      compositionService: CompositionService.shared,
      statsService: StatsService.shared,
      selectedTeamStore: SelectedTeamStore(
        userDefaults: UserDefaults(suiteName: "TeamTestSupport-\(UUID().uuidString)")!
      ),
      authService: auth,
      statsViewModel: TeamStatsViewModel(statsService: statsService),
      invitationsViewModel: TeamInvitationsViewModel(teamService: managementService),
      joinRequestsViewModel: TeamJoinRequestsViewModel(teamService: managementService),
      compositionsViewModel: TeamCompositionsViewModel(compositionService: compositionService),
      rosterViewModel: TeamRosterViewModel(teamService: managementService)
    )
    viewModel.applyPreviewState(teams: [resolvedTeam], selectedTeam: resolvedTeam)
    return viewModel
  }
}
