//
//  TeamStatsViewModelTests.swift
//  LeVestiaireTests
//

import Foundation
import Testing
@testable import LeVestiaire

@MainActor
struct TeamStatsViewModelTests {
  @Test
  func rankingEntries_returnsScorersForScorersKind() {
    let host = TeamTestSupport.makeHost()
    host.statsViewModel.teamRankings = ViewModelTestFixtures.teamSeasonRankings()

    let entries = host.statsViewModel.rankingEntries(for: .scorers)

    #expect(entries.count == 1)
    #expect(entries.first?.goals == 5)
  }

  @Test
  func loadSeasonsIfNeeded_setsDefaultSeason() async {
    let statsService = MockStatsService()
    statsService.fetchAvailableSeasonsHandler = { ["2025-2026", "2024-2025"] }
    let host = TeamTestSupport.makeHost(statsService: statsService)

    await host.statsViewModel.loadSeasonsIfNeeded()

    #expect(host.statsViewModel.availableSeasons == ["2025-2026", "2024-2025"])
    #expect(host.statsViewModel.selectedStatsSeason == "2025-2026")
    #expect(host.statsViewModel.seasonsTeamId == "team-admin")
  }

  @Test
  func loadStats_populatesPayloads() async {
    let stats = ViewModelTestFixtures.teamSeasonStats()
    let statsService = MockStatsService()
    statsService.fetchTeamSeasonStatsHandler = { _, season in
      #expect(season == "2025-2026")
      return stats
    }
    statsService.fetchTeamSeasonInsightsHandler = { _, _ in TeamSeasonInsightsPayload() }
    statsService.fetchTeamSeasonDuosHandler = { _, _, _ in TeamSeasonDuosPayload() }
    let host = TeamTestSupport.makeHost(statsService: statsService)
    host.statsViewModel.selectedStatsSeason = "2025-2026"

    await host.statsViewModel.loadStats()

    #expect(host.statsViewModel.teamSeasonStats == stats)
    #expect(host.statsViewModel.isLoadingStats == false)
  }

  @Test
  func loadRankings_populatesRankings() async {
    let rankings = ViewModelTestFixtures.teamSeasonRankings()
    let statsService = MockStatsService()
    statsService.fetchTeamSeasonRankingsHandler = { teamId, season in
      #expect(teamId == "team-admin")
      #expect(season == "2025-2026")
      return rankings
    }
    let host = TeamTestSupport.makeHost(statsService: statsService)
    host.statsViewModel.selectedRankingSeason = "2025-2026"

    await host.statsViewModel.loadRankings()

    #expect(host.statsViewModel.teamRankings == rankings)
    #expect(host.statsViewModel.rankingsLoadError == nil)
  }

  @Test
  func loadIfNeeded_skipsRosterTab() async {
    var didFetch = false
    let statsService = MockStatsService()
    statsService.fetchTeamSeasonStatsHandler = { _, _ in
      didFetch = true
      return nil
    }
    let host = TeamTestSupport.makeHost(statsService: statsService)
    host.statsViewModel.selectedStatsSeason = "2025-2026"

    await host.statsViewModel.loadIfNeeded(.roster, force: true)

    #expect(didFetch == false)
  }

  @Test
  func resetCache_clearsLoadedState() {
    let host = TeamTestSupport.makeHost()
    host.statsViewModel.teamSeasonStats = ViewModelTestFixtures.teamSeasonStats()
    host.statsViewModel.statsLoadedForTeamId = "team-admin"

    host.statsViewModel.resetCache()

    #expect(host.statsViewModel.teamSeasonStats == nil)
    #expect(host.statsViewModel.statsLoadedForTeamId == nil)
  }
}
