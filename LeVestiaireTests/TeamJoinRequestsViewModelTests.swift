//
//  TeamJoinRequestsViewModelTests.swift
//  LeVestiaireTests
//

import Foundation
import Testing
@testable import LeVestiaire

@MainActor
struct TeamJoinRequestsViewModelTests {
  @Test
  func pendingCount_filtersOnlyPendingRequests() {
    let host = TeamTestSupport.makeHost()
    host.joinRequestsViewModel.joinRequests = [
      ViewModelTestFixtures.joinRequest(id: "r-1", status: .pending),
      ViewModelTestFixtures.joinRequest(id: "r-2", status: .approved),
    ]

    #expect(host.joinRequestsViewModel.pendingCount == 1)
  }

  @Test
  func loadIfNeeded_skipsWhenCannotManageTeam() async {
    let host = TeamTestSupport.makeHost(team: ViewModelTestFixtures.playerTeam)
    var didFetch = false
    let teamService = MockTeamManagementService()
    teamService.fetchTeamJoinRequestsHandler = { _, _ in
      didFetch = true
      return []
    }
    let managedHost = TeamTestSupport.makeHost(
      team: ViewModelTestFixtures.playerTeam,
      teamService: teamService
    )

    await managedHost.joinRequestsViewModel.loadIfNeeded()

    #expect(didFetch == false)
    #expect(managedHost.joinRequestsViewModel.joinRequests.isEmpty)
  }

  @Test
  func loadIfNeeded_loadsPendingRequestsForManager() async {
    let request = ViewModelTestFixtures.joinRequest()
    let teamService = MockTeamManagementService()
    teamService.fetchTeamJoinRequestsHandler = { teamId, status in
      #expect(teamId == "team-admin")
      #expect(status == .pending)
      return [request]
    }
    let host = TeamTestSupport.makeHost(teamService: teamService)

    await host.joinRequestsViewModel.loadIfNeeded()

    #expect(host.joinRequestsViewModel.joinRequests == [request])
    #expect(host.joinRequestsViewModel.loadError == nil)
  }

  @Test
  func reviewRequest_approvesPendingRequest() async {
    let request = ViewModelTestFixtures.joinRequest()
    let teamService = MockTeamManagementService()
    var reviewedAction: TeamJoinRequestReviewAction?
    teamService.fetchTeamJoinRequestsHandler = { _, _ in [] }
    teamService.reviewJoinRequestHandler = { _, _, action in
      reviewedAction = action
    }
    let host = TeamTestSupport.makeHost(teamService: teamService)

    await host.joinRequestsViewModel.reviewRequest(request, action: .approve)

    #expect(reviewedAction == .approve)
    #expect(host.toastMessage != nil)
  }

  @Test
  func resetCache_clearsState() {
    let host = TeamTestSupport.makeHost()
    host.joinRequestsViewModel.joinRequests = [ViewModelTestFixtures.joinRequest()]
    host.joinRequestsViewModel.loadError = "error"

    host.joinRequestsViewModel.resetCache()

    #expect(host.joinRequestsViewModel.joinRequests.isEmpty)
    #expect(host.joinRequestsViewModel.loadError == nil)
  }
}
