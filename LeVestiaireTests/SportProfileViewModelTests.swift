//
//  SportProfileViewModelTests.swift
//  LeVestiaireTests
//

import Foundation
import Testing
@testable import LeVestiaire

@MainActor
struct SportProfileViewModelTests {
  @MainActor
  private func makeViewModel(
    mode: SportProfileMode = .onboarding,
    sportProfileService: MockSportProfileService,
    referenceDataService: MockReferenceDataService,
    authService: MockAuthService
  ) -> SportProfileViewModel {
    SportProfileViewModel(
      mode: mode,
      sportProfileService: sportProfileService,
      referenceDataService: referenceDataService,
      authService: authService
    )
  }

  private func fillRequiredFields(_ viewModel: SportProfileViewModel) {
    viewModel.selectedTeam = "PSG"
    viewModel.selectedPositions = [.centerMidfielder]
    viewModel.selectedWeekdays = [.monday]
    viewModel.jerseyNumberText = "10"
  }

  @Test
  func canSubmit_isFalseWhenRequiredFieldsMissing() {
    let viewModel = makeViewModel(
      sportProfileService: MockSportProfileService(),
      referenceDataService: MockReferenceDataService(),
      authService: MockAuthService()
    )
    #expect(viewModel.canSubmit == false)
  }

  @Test
  func canSubmit_isTrueWhenRequiredFieldsFilled() {
    let viewModel = makeViewModel(
      sportProfileService: MockSportProfileService(),
      referenceDataService: MockReferenceDataService(),
      authService: MockAuthService()
    )
    fillRequiredFields(viewModel)
    #expect(viewModel.canSubmit)
  }

  @Test
  func updateJerseyNumber_filtersNonNumericInput() {
    let viewModel = makeViewModel(
      sportProfileService: MockSportProfileService(),
      referenceDataService: MockReferenceDataService(),
      authService: MockAuthService()
    )
    viewModel.updateJerseyNumber("1a2b3")
    #expect(viewModel.jerseyNumberText == "123")
  }

  @Test
  func onLeagueChanged_reloadsAvailableTeams() {
    let reference = MockReferenceDataService()
    reference.teamsByLeague[FootballLeague.premierLeague.rawValue] = ["Arsenal"]
    let viewModel = makeViewModel(
      sportProfileService: MockSportProfileService(),
      referenceDataService: reference,
      authService: MockAuthService()
    )

    viewModel.selectedLeague = .premierLeague
    viewModel.onLeagueChanged()

    #expect(viewModel.availableTeams == ["Arsenal"])
    #expect(viewModel.selectedTeam == "Arsenal")
  }

  @Test
  func finalizeProfile_setsValidationMessageWhenIncomplete() {
    let viewModel = makeViewModel(
      sportProfileService: MockSportProfileService(),
      referenceDataService: MockReferenceDataService(),
      authService: MockAuthService()
    )
    viewModel.finalizeProfile()
    #expect(viewModel.validationMessage != nil)
  }

  @Test
  func finalizeProfile_marksSportProfileCompletedInOnboarding() async {
    let auth = MockAuthService()
    let sportProfile = MockSportProfileService()
    sportProfile.saveProfileHandler = { _ in
      SportProfileResponse(
        success: true,
        data: ViewModelTestFixtures.sportProfileData()
      )
    }
    let viewModel = makeViewModel(
      sportProfileService: sportProfile,
      referenceDataService: MockReferenceDataService(),
      authService: auth
    )
    fillRequiredFields(viewModel)

    viewModel.finalizeProfile()
    await AsyncTestSupport.waitUntil { auth.markSportProfileCompletedCallCount == 1 }

    #expect(auth.markSportProfileCompletedCallCount == 1)
  }

  @Test
  func loadExistingProfileIfNeeded_appliesStoredProfileInEditMode() async {
    let sportProfile = MockSportProfileService()
    sportProfile.fetchProfileHandler = {
      SportProfileResponse(
        success: true,
        data: ViewModelTestFixtures.sportProfileData(team: "OM", league: "ligue-1")
      )
    }
    let viewModel = makeViewModel(
      mode: .edit,
      sportProfileService: sportProfile,
      referenceDataService: MockReferenceDataService(),
      authService: MockAuthService()
    )

    await viewModel.loadExistingProfileIfNeeded()

    #expect(viewModel.selectedTeam == "OM")
    #expect(viewModel.jerseyNumberText == "10")
    #expect(viewModel.isEditMode)
  }
}
