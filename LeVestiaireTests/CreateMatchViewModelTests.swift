//
//  CreateMatchViewModelTests.swift
//  LeVestiaireTests
//

import Foundation
import Testing
@testable import LeVestiaire

@MainActor
struct CreateMatchViewModelTests {
  private func makeViewModel(
    matchService: MockMatchListingService,
    teamService: MockTeamJoinService,
    auth: MockAuthService
  ) -> CreateMatchViewModel {
    CreateMatchViewModel(
      matchService: matchService,
      teamService: teamService,
      authService: auth
    )
  }

  @Test
  func canSubmit_isFalseWhenRequiredFieldsMissing() {
    let auth = MockAuthService()
    auth.currentUser = ViewModelTestFixtures.user
    let viewModel = makeViewModel(
      matchService: MockMatchListingService(),
      teamService: MockTeamJoinService(),
      auth: auth
    )

    #expect(viewModel.canSubmit == false)
  }

  @Test
  func manageableTeams_filtersInactiveAndNonManageableTeams() async {
    let auth = MockAuthService()
    auth.currentUser = ViewModelTestFixtures.user
    let teamService = MockTeamJoinService()
    teamService.fetchUserTeamsHandler = {
      [
        ViewModelTestFixtures.adminTeam,
        ViewModelTestFixtures.playerTeam,
        SquadTeam(
          id: "team-inactive",
          name: "Inactive",
          adminId: "user-1",
          currentUserRole: .admin,
          isActive: false
        ),
      ]
    }
    let viewModel = makeViewModel(
      matchService: MockMatchListingService(),
      teamService: teamService,
      auth: auth
    )

    await viewModel.loadTeams(force: true)

    #expect(viewModel.manageableTeams.map(\.id) == ["team-admin"])
    #expect(viewModel.hasInactiveManageableTeams)
    #expect(viewModel.selectedTeamId == "team-admin")
  }

  @Test
  func createMatch_onSuccess_returnsDetail() async {
    let auth = MockAuthService()
    auth.currentUser = ViewModelTestFixtures.user
    let matchService = MockMatchListingService()
    let expected = ViewModelTestFixtures.matchDetail(id: "created-match")
    matchService.createMatchHandler = { _ in expected }
    let teamService = MockTeamJoinService()
    teamService.fetchUserTeamsHandler = { [ViewModelTestFixtures.adminTeam] }
    let viewModel = makeViewModel(matchService: matchService, teamService: teamService, auth: auth)
    await viewModel.loadTeams(force: true)
    viewModel.opponentTeam = "Rival FC"
    viewModel.location = "Stade"
    viewModel.selectedTeamId = "team-admin"

    let created = await viewModel.createMatch()

    #expect(created?.id == "created-match")
    #expect(viewModel.errorMessage == nil)
  }

  @Test
  func createMatch_whenNotSubmittable_returnsNil() async {
    let viewModel = makeViewModel(
      matchService: MockMatchListingService(),
      teamService: MockTeamJoinService(),
      auth: MockAuthService()
    )

    let created = await viewModel.createMatch()

    #expect(created == nil)
  }
}
