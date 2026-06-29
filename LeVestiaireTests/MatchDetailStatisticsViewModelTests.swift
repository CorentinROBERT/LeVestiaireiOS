//
//  MatchDetailStatisticsViewModelTests.swift
//  LeVestiaireTests
//

import Foundation
import Testing
@testable import LeVestiaire

@MainActor
struct MatchDetailStatisticsViewModelTests {
  @Test
  func loadIfNeeded_skipsDraftMatches() async {
    var didFetchStats = false
    let matchService = MockMatchDetailService()
    matchService.fetchMatchStatsHandler = { _ in
      didFetchStats = true
      return ViewModelTestFixtures.matchStats()
    }
    let match = ViewModelTestFixtures.matchDetail(id: "match-1", status: .draft)
    let viewModel = MatchDetailTestSupport.makeViewModel(
      match: match,
      matchService: matchService
    )

    await viewModel.statisticsViewModel.loadIfNeeded(force: true)

    #expect(didFetchStats == false)
    #expect(viewModel.statisticsViewModel.matchStats == nil)
    #expect(viewModel.statisticsViewModel.hasLoadedMatchStats == false)
  }

  @Test
  func loadIfNeeded_loadsStatsForFinishedMatch() async {
    let payload = ViewModelTestFixtures.matchStats(goals: 3)
    let matchService = MockMatchDetailService()
    matchService.fetchMatchStatsHandler = { _ in payload }
    let match = ViewModelTestFixtures.matchDetail(id: "match-1", status: .finished)
    let viewModel = MatchDetailTestSupport.makeViewModel(
      match: match,
      matchService: matchService
    )

    await viewModel.statisticsViewModel.loadIfNeeded(force: true)

    #expect(viewModel.statisticsViewModel.matchStats == payload)
    #expect(viewModel.statisticsViewModel.hasLoadedMatchStats)
    #expect(viewModel.statisticsViewModel.isLoadingMatchStats == false)
  }

  @Test
  func loadIfNeeded_skipsWhenAlreadyLoaded() async {
    var fetchCount = 0
    let matchService = MockMatchDetailService()
    matchService.fetchMatchStatsHandler = { _ in
      fetchCount += 1
      return ViewModelTestFixtures.matchStats()
    }
    let match = ViewModelTestFixtures.matchDetail(id: "match-1", status: .ongoing)
    let viewModel = MatchDetailTestSupport.makeViewModel(
      match: match,
      matchService: matchService
    )

    await viewModel.statisticsViewModel.loadIfNeeded()
    await viewModel.statisticsViewModel.loadIfNeeded()

    #expect(fetchCount == 1)
  }

  @Test
  func loadIfNeeded_surfacesServiceError() async {
    let matchService = MockMatchDetailService()
    matchService.fetchMatchStatsHandler = { _ in
      throw MatchServiceError.unauthorized
    }
    let match = ViewModelTestFixtures.matchDetail(id: "match-1", status: .finished)
    let viewModel = MatchDetailTestSupport.makeViewModel(
      match: match,
      matchService: matchService
    )

    await viewModel.statisticsViewModel.loadIfNeeded(force: true)

    #expect(viewModel.statisticsViewModel.matchStats == nil)
    #expect(viewModel.errorMessage == L10n.sessionRequired)
  }

  @Test
  func resetCache_clearsLoadedState() {
    let viewModel = MatchDetailTestSupport.makeViewModel(
      match: ViewModelTestFixtures.matchDetail(id: "match-1", status: .finished),
      matchService: MockMatchDetailService()
    )
    viewModel.statisticsViewModel.matchStats = ViewModelTestFixtures.matchStats()
    viewModel.statisticsViewModel.hasLoadedMatchStats = true

    viewModel.statisticsViewModel.resetCache()

    #expect(viewModel.statisticsViewModel.matchStats == nil)
    #expect(viewModel.statisticsViewModel.hasLoadedMatchStats == false)
  }
}
