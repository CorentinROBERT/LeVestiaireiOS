//
//  ContentViewModelTests.swift
//  LeVestiaireTests
//

import Testing
@testable import LeVestiaire

@MainActor
struct ContentViewModelTests {
  @Test
  func init_startsOnLandingWhenOnboardingIncomplete() {
    let store = MockOnboardingStore()
    let viewModel = ContentViewModel(onboardingStore: store)

    #expect(viewModel.currentScreen == .landing)
    #expect(viewModel.landingItems.isEmpty == false)
  }

  @Test
  func init_startsOnLoginWhenOnboardingCompleted() {
    let store = MockOnboardingStore()
    store.hasCompletedOnboarding = true
    let viewModel = ContentViewModel(onboardingStore: store)

    #expect(viewModel.currentScreen == .login)
  }

  @Test
  func completeOnboarding_switchesToLogin() {
    let store = MockOnboardingStore()
    let viewModel = ContentViewModel(onboardingStore: store)

    viewModel.completeOnboarding()

    #expect(store.hasCompletedOnboarding)
    #expect(viewModel.currentScreen == .login)
  }
}
