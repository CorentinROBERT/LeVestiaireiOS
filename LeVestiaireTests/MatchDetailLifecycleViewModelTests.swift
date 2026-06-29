//
//  MatchDetailLifecycleViewModelTests.swift
//  LeVestiaireTests
//

import Foundation
import Testing
@testable import LeVestiaire

@MainActor
struct MatchDetailLifecycleViewModelTests {
  @Test
  func publishMatch_returnsFalseWhenCannotPublish() async {
    let match = ViewModelTestFixtures.matchDetail(id: "match-1", status: .draft)
    let viewModel = MatchDetailTestSupport.makeViewModel(
      match: match,
      matchService: MockMatchDetailService()
    )

    let didPublish = await viewModel.publishMatch()

    #expect(didPublish == false)
  }

  @Test
  func publishMatch_succeedsWhenAllowed() async {
    let composition = TeamPreviewData.compositions.first!
    let matchService = MockMatchDetailService()
    let draft = ViewModelTestFixtures.matchDetail(
      id: "match-1",
      status: .draft,
      capabilities: MatchCapabilities(
        canRespond: false,
        canManageAvailability: true,
        canManageComposition: true,
        canPublish: true,
        canStartMatch: false,
        canManageEvents: false,
        canUpdateScore: false,
        canFinishMatch: false
      ),
      composition: composition
    )
    let published = ViewModelTestFixtures.copy(draft, status: .upcoming)
    matchService.publishMatchHandler = { _ in published }
    let viewModel = MatchDetailTestSupport.makeViewModel(
      match: draft,
      matchService: matchService
    )

    let didPublish = await viewModel.publishMatch()

    #expect(didPublish)
    #expect(viewModel.match?.status == .upcoming)
  }

  @Test
  func updateScore_returnsFalseWithoutCapability() async {
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
        canUpdateScore: false,
        canFinishMatch: false
      )
    )
    let viewModel = MatchDetailTestSupport.makeViewModel(
      match: match,
      matchService: MockMatchDetailService()
    )

    let didUpdate = await viewModel.updateScore(home: 2, away: 1)

    #expect(didUpdate == false)
  }

  @Test
  func updateScore_succeedsWhenAllowed() async {
    let matchService = MockMatchDetailService()
    let ongoing = ViewModelTestFixtures.matchDetail(
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
    let scored = ViewModelTestFixtures.copy(ongoing, homeScore: 2, awayScore: 1)
    matchService.updateScoreHandler = { _, home, away in
      #expect(home == 2)
      #expect(away == 1)
      return scored
    }
    let viewModel = MatchDetailTestSupport.makeViewModel(
      match: ongoing,
      matchService: matchService
    )

    let didUpdate = await viewModel.updateScore(home: 2, away: 1)

    #expect(didUpdate)
    #expect(viewModel.match?.homeScore == 2)
    #expect(viewModel.match?.awayScore == 1)
  }

  @Test
  func startMatch_succeedsWhenAllowed() async {
    let matchService = MockMatchDetailService()
    let upcoming = ViewModelTestFixtures.matchDetail(
      id: "match-1",
      status: .upcoming,
      capabilities: MatchCapabilities(
        canRespond: false,
        canManageAvailability: false,
        canManageComposition: false,
        canPublish: false,
        canStartMatch: true,
        canManageEvents: true,
        canUpdateScore: true,
        canFinishMatch: true
      )
    )
    let ongoing = ViewModelTestFixtures.copy(upcoming, status: .ongoing)
    matchService.updateMatchStatusHandler = { _, status in
      #expect(status == .ongoing)
      return ongoing
    }
    let viewModel = MatchDetailTestSupport.makeViewModel(
      match: upcoming,
      matchService: matchService
    )

    let didStart = await viewModel.startMatch()

    #expect(didStart)
    #expect(viewModel.match?.status == .ongoing)
  }

  @Test
  func finishMatch_succeedsWhenAllowed() async {
    let matchService = MockMatchDetailService()
    let ongoing = ViewModelTestFixtures.matchDetail(
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
    let finished = ViewModelTestFixtures.copy(ongoing, status: .finished)
    matchService.updateMatchStatusHandler = { _, status in
      #expect(status == .finished)
      return finished
    }
    let viewModel = MatchDetailTestSupport.makeViewModel(
      match: ongoing,
      matchService: matchService
    )

    let didFinish = await viewModel.finishMatch()

    #expect(didFinish)
    #expect(viewModel.match?.status == .finished)
  }

  @Test
  func cancelMatch_returnsFalseWithoutLifecycleRights() async {
    let match = ViewModelTestFixtures.matchDetail(id: "match-1", status: .draft)
    let viewModel = MatchDetailTestSupport.makeViewModel(
      match: match,
      matchService: MockMatchDetailService()
    )

    let didCancel = await viewModel.cancelMatch()

    #expect(didCancel == false)
  }

  @Test
  func cancelMatch_succeedsForManager() async {
    let matchService = MockMatchDetailService()
    let draft = ViewModelTestFixtures.matchDetail(
      id: "match-1",
      status: .draft,
      capabilities: MatchCapabilities(
        canRespond: false,
        canManageAvailability: true,
        canManageComposition: true,
        canPublish: true,
        canStartMatch: false,
        canManageEvents: false,
        canUpdateScore: false,
        canFinishMatch: false
      ),
      composition: TeamPreviewData.compositions.first
    )
    let cancelled = ViewModelTestFixtures.copy(draft, status: .cancelled)
    matchService.updateMatchStatusHandler = { _, status in
      #expect(status == .cancelled)
      return cancelled
    }
    let viewModel = MatchDetailTestSupport.makeViewModel(
      match: draft,
      matchService: matchService
    )

    let didCancel = await viewModel.cancelMatch()

    #expect(didCancel)
    #expect(viewModel.match?.status == .cancelled)
  }
}
