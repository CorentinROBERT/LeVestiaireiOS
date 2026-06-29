//
//  MatchDetailEventsViewModelTests.swift
//  LeVestiaireTests
//

import Foundation
import Testing
@testable import LeVestiaire

@MainActor
struct MatchDetailEventsViewModelTests {
  @Test
  func canManage_forFinishedMatchWhenTeamManager() {
    let match = ViewModelTestFixtures.matchDetail(
      id: "match-1",
      status: .finished,
      capabilities: MatchCapabilities(
        canRespond: false,
        canManageAvailability: false,
        canManageComposition: false,
        canPublish: false,
        canStartMatch: false,
        canManageEvents: false,
        canUpdateScore: true,
        canFinishMatch: false
      )
    )
    let viewModel = MatchDetailTestSupport.makeViewModel(
      match: match,
      matchService: MockMatchDetailService(),
      canManageMatchTeam: true
    )

    #expect(viewModel.eventsViewModel.canManage)
  }

  @Test
  func loadIfNeeded_skipsDraftMatches() async {
    var didFetchEvents = false
    let matchService = MockMatchDetailService()
    matchService.fetchEventsHandler = { _ in
      didFetchEvents = true
      return []
    }
    let match = ViewModelTestFixtures.matchDetail(id: "match-1", status: .draft)
    let viewModel = MatchDetailTestSupport.makeViewModel(
      match: match,
      matchService: matchService
    )

    await viewModel.eventsViewModel.loadIfNeeded(force: true)

    #expect(didFetchEvents == false)
    #expect(viewModel.eventsViewModel.events.isEmpty)
    #expect(viewModel.eventsViewModel.hasLoadedEvents == false)
  }

  @Test
  func delete_rejectsSystemGeneratedEvents() async throws {
    let match = ViewModelTestFixtures.matchDetail(
      id: "match-1",
      status: .ongoing,
      capabilities: MatchCapabilities(
        canRespond: false,
        canManageAvailability: false,
        canManageComposition: false,
        canPublish: false,
        canStartMatch: false,
        canManageEvents: true,
        canUpdateScore: true,
        canFinishMatch: true
      )
    )
    let viewModel = MatchDetailTestSupport.makeViewModel(
      match: match,
      matchService: MockMatchDetailService()
    )
    let systemEvent = try ViewModelTestFixtures.decodeMatchEvent(id: "start", type: "match_start")
    viewModel.eventsViewModel.events = [systemEvent]

    let didDelete = await viewModel.eventsViewModel.delete("start")

    #expect(didDelete == false)
  }

  @Test
  func loadIfNeeded_loadsEventsForOngoingMatch() async throws {
    let goalEvent = try ViewModelTestFixtures.decodeMatchEvent(id: "goal-1", type: "goal")
    let matchService = MockMatchDetailService()
    matchService.fetchEventsHandler = { _ in [goalEvent] }
    let match = ViewModelTestFixtures.matchDetail(
      id: "match-1",
      status: .ongoing,
      capabilities: MatchCapabilities(
        canRespond: false,
        canManageAvailability: false,
        canManageComposition: false,
        canPublish: false,
        canStartMatch: false,
        canManageEvents: true,
        canUpdateScore: true,
        canFinishMatch: true
      )
    )
    let viewModel = MatchDetailTestSupport.makeViewModel(
      match: match,
      matchService: matchService
    )

    await viewModel.eventsViewModel.loadIfNeeded(force: true)

    #expect(viewModel.eventsViewModel.events.map(\.id) == ["goal-1"])
    #expect(viewModel.eventsViewModel.hasLoadedEvents)
  }
}
