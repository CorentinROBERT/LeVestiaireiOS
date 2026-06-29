//
//  JoinTeamViewModelTests.swift
//  LeVestiaireTests
//

import Foundation
import SwiftUI
import Testing
@testable import LeVestiaire

@MainActor
struct JoinTeamViewModelTests {
  private func makeViewModel(teamService: MockTeamJoinService) -> JoinTeamViewModel {
    JoinTeamViewModel(teamService: teamService)
  }

  @Test
  func pendingJoinRequests_filtersOnlyPending() {
    let viewModel = makeViewModel(teamService: MockTeamJoinService())
    viewModel.myJoinRequests = [
      TeamJoinRequest(id: "r1", teamId: "t1", status: .pending),
      TeamJoinRequest(id: "r2", teamId: "t2", status: .approved),
    ]

    #expect(viewModel.pendingJoinRequests.map(\.id) == ["r1"])
  }

  @Test
  func search_withEmptyQuery_setsError() async {
    let viewModel = makeViewModel(teamService: MockTeamJoinService())
    viewModel.searchQuery = "   "

    await viewModel.search()

    #expect(viewModel.errorMessage == L10n.text("joinTeamSearchRequired"))
    #expect(viewModel.searchResults.isEmpty)
  }

  @Test
  func search_withResults_populatesList() async {
    let teamService = MockTeamJoinService()
    teamService.searchHandler = { _ in [ViewModelTestFixtures.searchResult] }
    let viewModel = makeViewModel(teamService: teamService)
    viewModel.searchQuery = "FC Test"

    await viewModel.search()

    #expect(viewModel.searchResults.count == 1)
    #expect(viewModel.errorMessage == nil)
    #expect(teamService.lastSearchQuery == "FC Test")
  }

  @Test
  func search_withNoResults_setsError() async {
    let teamService = MockTeamJoinService()
    teamService.searchHandler = { _ in [] }
    let viewModel = makeViewModel(teamService: teamService)
    viewModel.searchQuery = "Unknown"

    await viewModel.search()

    #expect(viewModel.searchResults.isEmpty)
    #expect(viewModel.errorMessage == L10n.text("joinTeamSearchNoResults"))
  }

  @Test
  func submitJoinRequest_whenAlreadyMember_returnsFalse() async {
    let viewModel = makeViewModel(teamService: MockTeamJoinService())
    let team = TeamSearchResult(id: "team-1", name: "FC Test", isMember: true)

    let didSubmit = await viewModel.submitJoinRequest(for: team)

    #expect(didSubmit == false)
  }

  @Test
  func submitJoinRequest_onSuccess_setsSuccessMessage() async {
    let teamService = MockTeamJoinService()
    teamService.createJoinRequestHandler = { teamId, _ in
      TeamJoinRequest(id: "request-1", teamId: teamId, status: .pending)
    }
    teamService.fetchMyJoinRequestsHandler = { [] }
    let viewModel = makeViewModel(teamService: teamService)
    let team = ViewModelTestFixtures.searchResult

    let didSubmit = await viewModel.submitJoinRequest(for: team)

    #expect(didSubmit)
    #expect(viewModel.successMessage != nil)
    #expect(teamService.lastJoinRequestTeamId == "team-1")
  }

  @Test
  func messageBinding_truncatesToMaxLength() {
    let viewModel = makeViewModel(teamService: MockTeamJoinService())
    let binding = viewModel.messageBinding(for: "team-1")
    binding.wrappedValue = String(repeating: "a", count: JoinTeamViewModel.messageMaxLength + 10)

    #expect(binding.wrappedValue.count == JoinTeamViewModel.messageMaxLength)
  }
}
