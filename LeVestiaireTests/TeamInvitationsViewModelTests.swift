//
//  TeamInvitationsViewModelTests.swift
//  LeVestiaireTests
//

import Foundation
import Testing
@testable import LeVestiaire

@MainActor
struct TeamInvitationsViewModelTests {
  @Test
  func loadIfNeeded_skipsWhenCannotManageTeam() async {
    var didFetch = false
    let teamService = MockTeamManagementService()
    teamService.fetchTeamInvitationsHandler = { _ in
      didFetch = true
      return []
    }
    let host = TeamTestSupport.makeHost(
      team: ViewModelTestFixtures.playerTeam,
      teamService: teamService
    )

    await host.invitationsViewModel.loadIfNeeded()

    #expect(didFetch == false)
    #expect(host.invitationsViewModel.teamInvitations.isEmpty)
  }

  @Test
  func loadIfNeeded_loadsInvitationsForManager() async {
    let invitation = ViewModelTestFixtures.teamInvitation()
    let teamService = MockTeamManagementService()
    teamService.fetchTeamInvitationsHandler = { teamId in
      #expect(teamId == "team-admin")
      return [invitation]
    }
    let host = TeamTestSupport.makeHost(teamService: teamService)

    await host.invitationsViewModel.loadIfNeeded()

    #expect(host.invitationsViewModel.teamInvitations == [invitation])
  }

  @Test
  func invitePlayer_withValidData_succeeds() async {
    let teamService = MockTeamManagementService()
    teamService.invitePlayerHandler = { _, _, _, _ in }
    teamService.fetchTeamInvitationsHandler = { _ in [] }
    let host = TeamTestSupport.makeHost(teamService: teamService)

    let didInvite = await host.invitationsViewModel.invitePlayer(
      email: "player@example.com",
      firstName: "Paul",
      lastName: "Durand"
    )

    #expect(didInvite)
    #expect(teamService.lastInvitedEmail == "player@example.com")
    #expect(host.toastMessage != nil)
  }

  @Test
  func invitePlayer_withEmptyEmail_returnsFalse() async {
    let host = TeamTestSupport.makeHost()

    let didInvite = await host.invitationsViewModel.invitePlayer(
      email: "   ",
      firstName: "Paul",
      lastName: nil
    )

    #expect(didInvite == false)
    #expect(host.alertMessage != nil)
  }

  @Test
  func cancelInvitation_clearsPendingAndReloads() async {
    let invitation = ViewModelTestFixtures.teamInvitation()
    let teamService = MockTeamManagementService()
    teamService.cancelInvitationHandler = { invitationId in
      #expect(invitationId == invitation.id)
    }
    teamService.fetchTeamInvitationsHandler = { _ in [] }
    let host = TeamTestSupport.makeHost(teamService: teamService)
    host.invitationsViewModel.invitationPendingCancellation = invitation

    await host.invitationsViewModel.cancelInvitation()

    #expect(host.invitationsViewModel.invitationPendingCancellation == nil)
    #expect(host.toastMessage != nil)
  }
}
