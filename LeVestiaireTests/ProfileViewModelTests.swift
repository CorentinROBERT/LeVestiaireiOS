//
//  ProfileViewModelTests.swift
//  LeVestiaireTests
//

import Foundation
import Testing
@testable import LeVestiaire

@MainActor
struct ProfileViewModelTests {
  @Test
  func loadProfile_populatesUserSportProfileAndSeasons() async {
    let auth = MockAuthService()
    auth.currentUser = ViewModelTestFixtures.user
    auth.fetchCurrentUserHandler = { _ in ViewModelTestFixtures.user }

    let sportProfile = MockSportProfileService()
    sportProfile.fetchProfileHandler = {
      SportProfileResponse(
        success: true,
        data: ViewModelTestFixtures.sportProfileData()
      )
    }

    let stats = MockStatsService()
    stats.fetchAvailableSeasonsHandler = { ["2024-2025", "2025-2026"] }
    stats.fetchUserSeasonStatsHandler = { _, _ in
      ViewModelTestFixtures.userSeasonStats()
    }

    let viewModel = ProfileViewModel(
      authService: auth,
      sportProfileService: sportProfile,
      statsService: stats,
      accountService: MockAccountService()
    )

    await viewModel.loadProfile()

    #expect(viewModel.user?.id == "user-1")
    #expect(viewModel.sportProfile?.favoriteTeam == "PSG")
    #expect(viewModel.availableSeasons.contains("2025-2026"))
    #expect(viewModel.seasonStats?.goals == 3)
    #expect(viewModel.isLoading == false)
  }

  @Test
  func logout_callsAuthService() async {
    let auth = MockAuthService()
    auth.currentUser = ViewModelTestFixtures.user
    let viewModel = ProfileViewModel(
      authService: auth,
      sportProfileService: MockSportProfileService(),
      statsService: MockStatsService(),
      accountService: MockAccountService()
    )

    viewModel.logout()
    await AsyncTestSupport.waitUntil { auth.logoutCallCount == 1 }

    #expect(auth.logoutCallCount == 1)
    #expect(viewModel.isLoggingOut == false)
  }

  @Test
  func requestAccountDeletion_showsSuccessAlert() async {
    let auth = MockAuthService()
    auth.currentUser = ViewModelTestFixtures.user
    let account = MockAccountService()
    account.requestAccountDeletionHandler = {
      AccountActionResponse(success: true, message: "scheduled")
    }
    let viewModel = ProfileViewModel(
      authService: auth,
      sportProfileService: MockSportProfileService(),
      statsService: MockStatsService(),
      accountService: account
    )

    viewModel.requestAccountDeletion()
    await AsyncTestSupport.waitUntil { viewModel.alertMessage != nil }

    #expect(viewModel.alertMessage != nil)
    #expect(viewModel.isDeletingAccount == false)
  }

  @Test
  func strongFootAndJerseyLabels_formatValues() {
    let viewModel = ProfileViewModel(
      authService: MockAuthService(),
      sportProfileService: MockSportProfileService(),
      statsService: MockStatsService(),
      accountService: MockAccountService()
    )

    #expect(viewModel.strongFootLabel(for: "right") != viewModel.strongFootLabel(for: nil))
    #expect(viewModel.jerseyNumberLabel(for: 7) == "7")
    #expect(viewModel.jerseyNumberLabel(for: nil) != "7")
  }
}
