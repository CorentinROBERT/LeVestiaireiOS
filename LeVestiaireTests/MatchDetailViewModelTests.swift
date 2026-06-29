//
//  MatchDetailViewModelTests.swift
//  LeVestiaireTests
//

import Foundation
import Testing
@testable import LeVestiaire

@MainActor
struct MatchDetailViewModelTests {
  @Test
  func showsRespondSection_whenPlayerCanRespond() {
    let match = ViewModelTestFixtures.matchDetail(
      id: "match-1",
      status: .draft,
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
    let viewModel = MatchDetailTestSupport.makeViewModel(
      match: match,
      matchService: MockMatchDetailService()
    )

    #expect(viewModel.showsRespondSection)
    #expect(viewModel.showsAvailabilityManagement == false)
  }

  @Test
  func showsAvailabilityManagement_forTeamManagerInPreparation() {
    let match = ViewModelTestFixtures.matchDetail(id: "match-1", status: .draft)
    let viewModel = MatchDetailTestSupport.makeViewModel(
      match: match,
      matchService: MockMatchDetailService(),
      canManageMatchTeam: true
    )

    #expect(viewModel.showsAvailabilityManagement)
  }

  @Test
  func surfaceError_mapsMatchServiceError() {
    let viewModel = MatchDetailTestSupport.makeViewModel(
      match: ViewModelTestFixtures.matchDetail(id: "match-1"),
      matchService: MockMatchDetailService()
    )

    viewModel.surfaceError(MatchServiceError.unauthorized)

    #expect(viewModel.errorMessage == L10n.sessionRequired)
  }

  @Test
  func surfaceError_ignoresCancellation() {
    let viewModel = MatchDetailTestSupport.makeViewModel(
      match: ViewModelTestFixtures.matchDetail(id: "match-1"),
      matchService: MockMatchDetailService()
    )

    viewModel.surfaceError(CancellationError())

    #expect(viewModel.errorMessage == nil)
  }

  @Test
  func load_populatesMatch() async {
    let matchService = MockMatchDetailService()
    let expected = ViewModelTestFixtures.matchDetail(id: "match-1", status: .upcoming)
    matchService.fetchMatchHandler = { _, _ in expected }
    let viewModel = MatchDetailTestSupport.makeViewModel(
      match: expected,
      matchService: matchService
    )
    viewModel.match = nil

    await viewModel.load()

    #expect(viewModel.match?.id == "match-1")
    #expect(viewModel.isLoading == false)
  }
}
