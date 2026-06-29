//
//  EditMatchViewModelTests.swift
//  LeVestiaireTests
//

import Foundation
import Testing
@testable import LeVestiaire

@MainActor
struct EditMatchViewModelTests {
  @Test
  func canSubmit_isFalseWhenRequiredFieldsMissing() {
    let match = ViewModelTestFixtures.matchDetail(id: "match-1")
    let viewModel = EditMatchViewModel(
      match: match,
      matchService: MockMatchDetailService()
    )
    viewModel.opponentTeam = ""
    viewModel.location = ""

    #expect(viewModel.canSubmit == false)
  }

  @Test
  func canSubmit_isTrueWithValidFields() {
    let match = ViewModelTestFixtures.matchDetail(id: "match-1")
    let viewModel = EditMatchViewModel(
      match: match,
      matchService: MockMatchDetailService()
    )
    viewModel.opponentTeam = "Rival FC"
    viewModel.location = "Stade municipal"

    #expect(viewModel.canSubmit)
  }

  @Test
  func init_prefillsFieldsFromMatch() {
    let date = Date(timeIntervalSince1970: 1_700_000_000)
    let match = ViewModelTestFixtures.matchDetail(id: "match-1", date: date)
    let viewModel = EditMatchViewModel(
      match: match,
      matchService: MockMatchDetailService()
    )

    #expect(viewModel.opponentTeam == "Opponent")
    #expect(viewModel.location == "Stade")
    #expect(viewModel.includesTime)
  }

  @Test
  func saveChanges_onSuccess_returnsUpdatedMatch() async {
    let matchService = MockMatchDetailService()
    let match = ViewModelTestFixtures.matchDetail(id: "match-1")
    let updated = ViewModelTestFixtures.copy(
      match,
      homeScore: nil,
      awayScore: nil
    )
    matchService.updateMatchHandler = { id, request in
      #expect(id == "match-1")
      #expect(request.opponentTeam == "Rival FC")
      #expect(request.location == "Stade")
      return updated
    }
    let viewModel = EditMatchViewModel(match: match, matchService: matchService)
    viewModel.opponentTeam = "Rival FC"
    viewModel.location = "Stade"

    let saved = await viewModel.saveChanges()

    #expect(saved?.id == "match-1")
    #expect(viewModel.errorMessage == nil)
    #expect(viewModel.isSubmitting == false)
  }

  @Test
  func saveChanges_whenNotSubmittable_returnsNil() async {
    let viewModel = EditMatchViewModel(
      match: ViewModelTestFixtures.matchDetail(id: "match-1"),
      matchService: MockMatchDetailService()
    )

    let saved = await viewModel.saveChanges()

    #expect(saved == nil)
  }
}
