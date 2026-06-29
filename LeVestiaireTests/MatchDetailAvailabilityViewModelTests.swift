//
//  MatchDetailAvailabilityViewModelTests.swift
//  LeVestiaireTests
//

import Foundation
import Testing
@testable import LeVestiaire

@MainActor
struct MatchDetailAvailabilityViewModelTests {
  @Test
  func showsPresentMembersList_forUpcomingMatchWithoutManagement() {
    let match = ViewModelTestFixtures.matchDetail(id: "match-1", status: .upcoming)
    let viewModel = MatchDetailTestSupport.makeViewModel(
      match: match,
      matchService: MockMatchDetailService()
    )

    #expect(viewModel.availabilityViewModel.showsPresentMembersList)
    #expect(viewModel.availabilityViewModel.showsManagement == false)
  }

  @Test
  func submitMyAvailability_updatesMatchOnSuccess() async {
    let matchService = MockMatchDetailService()
    let initial = ViewModelTestFixtures.matchDetail(
      id: "match-1",
      status: .draft,
      myAvailabilityStatus: nil,
      capabilities: MatchCapabilities(
        canRespond: true,
        canManageAvailability: false,
        canManageComposition: false,
        canPublish: false,
        canStartMatch: false,
        canManageEvents: false,
        canUpdateScore: false,
        canFinishMatch: false
      )
    )
    let updated = initial.replacingMyAvailabilityStatus(.available)
    matchService.fetchMatchHandler = { _, _ in updated }
    let viewModel = MatchDetailTestSupport.makeViewModel(
      match: initial,
      matchService: matchService
    )

    let didSubmit = await viewModel.availabilityViewModel.submitMyAvailability(.available)

    #expect(didSubmit)
    #expect(viewModel.match?.myAvailabilityStatus == .available)
    #expect(matchService.lastAvailabilityUpdate?.status == .available)
  }

  @Test
  func forcePlayerAvailability_returnsFalseWithoutManagementRights() async {
    let match = ViewModelTestFixtures.matchDetail(id: "match-1", status: .draft)
    let viewModel = MatchDetailTestSupport.makeViewModel(
      match: match,
      matchService: MockMatchDetailService()
    )
    viewModel.availabilityViewModel.availability = [
      MatchAvailabilityEntry(playerId: "player-1", userId: "player-1", status: .unknown),
    ]

    let didForce = await viewModel.availabilityViewModel.forcePlayerAvailability(
      playerId: "player-1",
      status: .available
    )

    #expect(didForce == false)
  }

  @Test
  func resetCache_clearsLoadedState() {
    let viewModel = MatchDetailTestSupport.makeViewModel(
      match: ViewModelTestFixtures.matchDetail(id: "match-1"),
      matchService: MockMatchDetailService()
    )
    viewModel.availabilityViewModel.availability = [
      MatchAvailabilityEntry(playerId: "player-1", status: .available),
    ]
    viewModel.availabilityViewModel.hasLoadedAvailability = true

    viewModel.availabilityViewModel.resetCache()

    #expect(viewModel.availabilityViewModel.availability.isEmpty)
    #expect(viewModel.availabilityViewModel.hasLoadedAvailability == false)
  }
}
