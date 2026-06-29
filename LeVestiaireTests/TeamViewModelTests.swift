//
//  TeamViewModelTests.swift
//  LeVestiaireTests
//

import Foundation
import Testing
@testable import LeVestiaire

@MainActor
struct TeamViewModelTests {
  @Test
  func canManageTeam_isTrueForAdminRole() {
    let auth = MockAuthService()
    auth.currentUser = ViewModelTestFixtures.user
    let viewModel = TeamViewModel(
      teamService: TeamService.shared,
      compositionService: CompositionService.shared,
      statsService: StatsService.shared,
      selectedTeamStore: SelectedTeamStore(userDefaults: UserDefaults(suiteName: "TeamViewModelTests")!),
      authService: auth
    )
    viewModel.applyPreviewState(
      teams: [ViewModelTestFixtures.adminTeam],
      selectedTeam: ViewModelTestFixtures.adminTeam
    )

    #expect(viewModel.canManageTeam)
    #expect(viewModel.canChangeMemberRoles)
  }

  @Test
  func canManageTeam_isFalseForPlayerRole() {
    let auth = MockAuthService()
    auth.currentUser = ViewModelTestFixtures.user
    let viewModel = TeamViewModel(
      teamService: TeamService.shared,
      compositionService: CompositionService.shared,
      statsService: StatsService.shared,
      selectedTeamStore: SelectedTeamStore(userDefaults: UserDefaults(suiteName: "TeamViewModelTests-player")!),
      authService: auth
    )
    viewModel.applyPreviewState(
      teams: [ViewModelTestFixtures.playerTeam],
      selectedTeam: ViewModelTestFixtures.playerTeam
    )

    #expect(viewModel.canManageTeam == false)
  }

  @Test
  func showsTeamDetailError_whenTeamsExistWithoutSelection() {
    let viewModel = TeamViewModel(
      teamService: TeamService.shared,
      compositionService: CompositionService.shared,
      statsService: StatsService.shared,
      selectedTeamStore: SelectedTeamStore(userDefaults: UserDefaults(suiteName: "TeamViewModelTests-error")!),
      authService: MockAuthService()
    )
    viewModel.applyPreviewState(teams: [ViewModelTestFixtures.team], selectedTeam: nil)
    viewModel.errorMessage = "load failed"

    #expect(viewModel.showsTeamDetailError)
  }

  @Test
  func applyLocalTeamUpdate_updatesSelectedTeamAndList() {
    let viewModel = TeamViewModel(
      teamService: TeamService.shared,
      compositionService: CompositionService.shared,
      statsService: StatsService.shared,
      selectedTeamStore: SelectedTeamStore(userDefaults: UserDefaults(suiteName: "TeamViewModelTests-update")!),
      authService: MockAuthService()
    )
    let original = SquadTeam(
      id: "team-1",
      name: "Old Name",
      memberCount: 3,
      currentUserRole: .admin
    )
    viewModel.applyPreviewState(teams: [original], selectedTeam: original)

    let updated = SquadTeam(
      id: "team-1",
      name: "New Name",
      memberCount: 4,
      currentUserRole: .admin
    )
    viewModel.applyLocalTeamUpdate(updated)

    #expect(viewModel.selectedTeam?.name == "New Name")
    #expect(viewModel.teams.first?.name == "New Name")
  }

  @Test
  func loadInitialData_populatesTeamsAndRestoresSelection() async throws {
    let teamService = MockTeamHostService()
    let teamA = ViewModelTestFixtures.adminTeam
    let teamB = ViewModelTestFixtures.playerTeam
    teamService.fetchMyTeamsHandler = {
      try ViewModelTestFixtures.myTeamsResponse(teams: [teamA, teamB])
    }
    teamService.fetchTeamHandler = { id in
      if id == teamA.id { return teamA }
      return teamB
    }
    let store = SelectedTeamStore(
      userDefaults: UserDefaults(suiteName: "TeamViewModelTests-load-\(UUID().uuidString)")!
    )
    store.selectedTeamId = teamB.id
    let viewModel = TeamViewModel(
      teamService: teamService,
      compositionService: CompositionService.shared,
      statsService: StatsService.shared,
      selectedTeamStore: store,
      authService: MockAuthService(),
      statsViewModel: TeamStatsViewModel(statsService: MockStatsService()),
      compositionsViewModel: TeamCompositionsViewModel(compositionService: MockCompositionService())
    )

    await viewModel.loadInitialData()

    #expect(viewModel.teams.count == 2)
    #expect(viewModel.selectedTeamId == teamB.id)
    #expect(viewModel.isLoading == false)
  }

  @Test
  func createTeam_appendsTeamAndSelectsIt() async {
    let teamService = MockTeamHostService()
    let created = SquadTeam(
      id: "team-new",
      name: "New FC",
      memberCount: 1,
      currentUserRole: .admin
    )
    teamService.createTeamHandler = { name, _, _ in
      #expect(name == "New FC")
      return created
    }
    teamService.fetchTeamHandler = { _ in created }
    let viewModel = TeamTestSupport.makeHost(teamService: teamService, hostTeamService: teamService)

    let success = await viewModel.createTeam(name: "New FC", description: nil, logo: nil)

    #expect(success)
    #expect(viewModel.teams.contains { $0.id == "team-new" })
    #expect(viewModel.selectedTeamId == "team-new")
  }

  @Test
  func createTeam_rejectsShortName() async {
    let viewModel = TeamTestSupport.makeHost()

    let success = await viewModel.createTeam(name: "A", description: nil, logo: nil)

    #expect(success == false)
    #expect(viewModel.alertMessage != nil)
  }

  @Test
  func deleteSelectedTeam_removesTeamFromList() async {
    let team = ViewModelTestFixtures.adminTeam
    let teamService = MockTeamHostService()
    teamService.deleteTeamHandler = { id in
      #expect(id == team.id)
    }
    teamService.fetchMyTeamsHandler = {
      try ViewModelTestFixtures.myTeamsResponse(teams: [])
    }
    teamService.fetchTeamHandler = { _ in throw TeamServiceError.requestFailed("gone") }
    let viewModel = TeamTestSupport.makeHost(team: team, teamService: teamService, hostTeamService: teamService)

    let success = await viewModel.deleteSelectedTeam()

    #expect(success)
    #expect(viewModel.teams.contains { $0.id == team.id } == false)
  }

  @Test
  func loadTeamInviteLink_setsLinkForAdmin() async throws {
    let team = ViewModelTestFixtures.adminTeam
    let inviteLink = try ViewModelTestFixtures.teamInviteLink(teamId: team.id)
    let teamService = MockTeamHostService()
    teamService.fetchTeamInviteLinkHandler = { teamId in
      #expect(teamId == team.id)
      return inviteLink
    }
    let viewModel = TeamTestSupport.makeHost(team: team, teamService: teamService, hostTeamService: teamService)

    await viewModel.loadTeamInviteLink()

    #expect(viewModel.teamInviteLink?.code == inviteLink.code)
    #expect(viewModel.isLoadingTeamInviteLink == false)
  }

  @Test
  func selectTeamFromNotification_selectsTeamWhenPresent() async throws {
    let team = ViewModelTestFixtures.adminTeam
    let teamService = MockTeamHostService()
    teamService.fetchMyTeamsHandler = {
      try ViewModelTestFixtures.myTeamsResponse(teams: [team])
    }
    teamService.fetchTeamHandler = { _ in team }
    let viewModel = TeamTestSupport.makeHost(team: team, teamService: teamService, hostTeamService: teamService)
    viewModel.teams = []
    viewModel.selectedTeamId = ""

    await viewModel.selectTeamFromNotification(id: team.id)

    #expect(viewModel.selectedTeamId == team.id)
  }
}
