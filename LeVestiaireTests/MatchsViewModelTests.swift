//
//  MatchsViewModelTests.swift
//  LeVestiaireTests
//

import Foundation
import Testing
@testable import LeVestiaire

@MainActor
struct MatchsViewModelTests {
  private func makeViewModel(
    matchService: MockMatchListingService,
    teamService: MockTeamJoinService
  ) -> MatchsViewModel {
    MatchsViewModel(matchService: matchService, teamService: teamService)
  }

  @Test
  func showsTeamFilter_whenMultipleTeams() {
    let viewModel = makeViewModel(
      matchService: MockMatchListingService(),
      teamService: MockTeamJoinService()
    )
    viewModel.applyPreviewState(
      matches: [],
      teams: [ViewModelTestFixtures.team, ViewModelTestFixtures.playerTeam]
    )

    #expect(viewModel.showsTeamFilter)
  }

  @Test
  func teamName_returnsMatchingTeamName() {
    let viewModel = makeViewModel(
      matchService: MockMatchListingService(),
      teamService: MockTeamJoinService()
    )
    viewModel.applyPreviewState(matches: [], teams: [ViewModelTestFixtures.team])

    #expect(viewModel.teamName(for: "team-1") == "FC Test")
    #expect(viewModel.teamName(for: "missing") == nil)
  }

  @Test
  func initialize_loadsMatchesAndTeams() async {
    let matchService = MockMatchListingService()
    let teamService = MockTeamJoinService()
    let item = ViewModelTestFixtures.matchItem(id: "match-1")
    matchService.fetchMatchesHandler = { _ in
      MatchListResponse(
        matches: [item],
        pagination: PaginationInfo(page: 1, limit: 10, total: 1, totalPages: 1, hasNextPage: false)
      )
    }
    teamService.fetchUserTeamsHandler = { [ViewModelTestFixtures.team] }
    let viewModel = makeViewModel(matchService: matchService, teamService: teamService)

    await viewModel.initialize()

    #expect(viewModel.matches.count == 1)
    #expect(viewModel.userTeams.count == 1)
    #expect(viewModel.isLoading == false)
  }

  @Test
  func resetFilters_clearsActiveFilters() async {
    let matchService = MockMatchListingService()
    matchService.fetchMatchesHandler = { _ in MatchListResponse() }
    let viewModel = makeViewModel(
      matchService: matchService,
      teamService: MockTeamJoinService()
    )
    viewModel.applyPreviewState(
      matches: [],
      teams: [],
      filters: MatchFilters(statuses: [.draft], teamIds: ["team-1"])
    )

    await viewModel.resetFilters()

    #expect(viewModel.filters.hasActiveFilters == false)
    #expect(matchService.lastFetchCriteria?.statuses.isEmpty == true)
  }

  @Test
  func updateMatchInListing_removesItemExcludedByFilters() {
    let viewModel = makeViewModel(
      matchService: MockMatchListingService(),
      teamService: MockTeamJoinService()
    )
    let existing = ViewModelTestFixtures.matchItem(id: "match-1", status: .upcoming)
    viewModel.applyPreviewState(
      matches: [existing],
      teams: [ViewModelTestFixtures.team],
      filters: MatchFilters(statuses: [.upcoming])
    )

    let finished = ViewModelTestFixtures.matchDetail(id: "match-1", status: .finished)
    viewModel.updateMatchInListing(finished)

    #expect(viewModel.matches.isEmpty)
    #expect(viewModel.totalItems == 0)
  }

  @Test
  func submitAvailability_onSuccess_updatesListingItem() async {
    let matchService = MockMatchListingService()
    let existing = ViewModelTestFixtures.matchItem(id: "match-1", status: .draft)
    matchService.fetchMatchHandler = { id, _ in
      ViewModelTestFixtures.matchDetail(
        id: id,
        status: .draft,
        myAvailabilityStatus: .available
      )
    }
    let viewModel = makeViewModel(
      matchService: matchService,
      teamService: MockTeamJoinService()
    )
    viewModel.applyPreviewState(
      matches: [existing],
      teams: [ViewModelTestFixtures.team]
    )

    await viewModel.submitAvailability(for: "match-1", status: .available)

    #expect(viewModel.matches.first?.myAvailabilityStatus == .available)
    #expect(matchService.lastAvailabilityUpdate?.status == .available)
    #expect(viewModel.availabilityFeedback == nil)
  }

  @Test
  func submitAvailability_onFailure_setsFeedback() async {
    let matchService = MockMatchListingService()
    matchService.updateMyAvailabilityHandler = { _, _ in
      throw MatchServiceError.availabilityClosed
    }
    let viewModel = makeViewModel(
      matchService: matchService,
      teamService: MockTeamJoinService()
    )
    viewModel.applyPreviewState(
      matches: [ViewModelTestFixtures.matchItem(id: "match-1")],
      teams: [ViewModelTestFixtures.team]
    )

    await viewModel.submitAvailability(for: "match-1", status: .absent)

    #expect(viewModel.availabilityFeedback == L10n.availabilityClosed)
  }
}
