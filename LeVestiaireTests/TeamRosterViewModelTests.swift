//
//  TeamRosterViewModelTests.swift
//  LeVestiaireTests
//

import Foundation
import Testing
@testable import LeVestiaire

@MainActor
struct TeamRosterViewModelTests {
  @Test
  func mergeableTeamMembers_excludesGuests() {
    let guest = CompositionTestFixtures.guest
    let team = SquadTeam(
      id: "team-admin",
      name: "FC Admin",
      adminId: "user-1",
      members: CompositionTestFixtures.sevenStarterMembers() + [guest],
      memberCount: 8,
      currentUserRole: .admin
    )
    let host = TeamTestSupport.makeHost(team: team)

    let mergeable = host.rosterViewModel.mergeableTeamMembers

    #expect(mergeable.allSatisfy { !$0.isGuest })
    #expect(mergeable.count == 7)
  }

  @Test
  func addGuest_withValidData_succeeds() async {
    let teamService = MockTeamManagementService()
    teamService.addGuestHandler = { teamId, request in
      #expect(teamId == "team-admin")
      #expect(request.firstName == "Invité")
    }
    let host = TeamTestSupport.makeHost(teamService: teamService)

    let didAdd = await host.rosterViewModel.addGuest(
      firstName: "Invité",
      lastName: "Test",
      email: nil,
      jerseyNumber: 10
    )

    #expect(didAdd)
    #expect(host.toastMessage != nil)
  }

  @Test
  func addGuest_withEmptyFirstName_returnsFalse() async {
    let host = TeamTestSupport.makeHost()

    let didAdd = await host.rosterViewModel.addGuest(
      firstName: "   ",
      lastName: nil,
      email: nil,
      jerseyNumber: nil
    )

    #expect(didAdd == false)
    #expect(host.alertMessage != nil)
  }

  @Test
  func addGuest_withInvalidJerseyNumber_returnsFalse() async {
    let host = TeamTestSupport.makeHost()

    let didAdd = await host.rosterViewModel.addGuest(
      firstName: "Invité",
      lastName: nil,
      email: nil,
      jerseyNumber: 120
    )

    #expect(didAdd == false)
    #expect(host.alertMessage != nil)
  }

  @Test
  func updateMemberRole_returnsEarlyWithoutRights() async {
    var didUpdate = false
    let teamService = MockTeamManagementService()
    teamService.updateMemberRoleHandler = { _, _, _ in
      didUpdate = true
      return ViewModelTestFixtures.managedTeam
    }
    let host = TeamTestSupport.makeHost(
      team: ViewModelTestFixtures.playerTeam,
      teamService: teamService
    )
    let member = CompositionTestFixtures.alice

    await host.rosterViewModel.updateMemberRole(member: member, role: .manager)

    #expect(didUpdate == false)
    #expect(host.toastMessage == nil)
  }

  @Test
  func transferAdministration_succeedsForManager() async {
    let updatedTeam = ViewModelTestFixtures.managedTeam
    let teamService = MockTeamManagementService()
    teamService.updateMemberRoleHandler = { _, memberId, role in
      #expect(memberId == "user-2")
      #expect(role == .admin)
      return updatedTeam
    }
    let host = TeamTestSupport.makeHost(teamService: teamService)

    let didTransfer = await host.rosterViewModel.transferAdministration(to: "user-2")

    #expect(didTransfer)
    #expect(host.toastMessage != nil)
  }
}
