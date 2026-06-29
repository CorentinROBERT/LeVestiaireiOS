//
//  LoginViewModelTests.swift
//  LeVestiaireTests
//

import Foundation
import Testing
@testable import LeVestiaire

@MainActor
struct LoginViewModelTests {
  private func makeViewModel(
    auth: MockAuthService,
    savedEmailStore: InMemorySavedLoginEmailStore,
    pendingStore: InMemoryPendingCredentialsStore,
    biometricStore: MockBiometricAuthStore,
    inviteCoordinator: MockTeamInviteCoordinator
  ) -> LoginViewModel {
    LoginViewModel(
      authService: auth,
      savedEmailStore: savedEmailStore,
      pendingCredentialsStore: pendingStore,
      biometricStore: biometricStore,
      teamInviteCoordinator: inviteCoordinator
    )
  }

  @Test
  func login_withEmptyEmail_setsValidationMessage() {
    let viewModel = makeViewModel(
      auth: MockAuthService(),
      savedEmailStore: InMemorySavedLoginEmailStore(),
      pendingStore: InMemoryPendingCredentialsStore(),
      biometricStore: MockBiometricAuthStore(),
      inviteCoordinator: MockTeamInviteCoordinator()
    )
    viewModel.email = "   "
    viewModel.password = "secret"

    viewModel.login()

    #expect(viewModel.validationMessage == L10n.pleaseEnterYourEmail)
    #expect(viewModel.isLoading == false)
  }

  @Test
  func login_withEmptyPassword_setsValidationMessage() {
    let viewModel = makeViewModel(
      auth: MockAuthService(),
      savedEmailStore: InMemorySavedLoginEmailStore(),
      pendingStore: InMemoryPendingCredentialsStore(),
      biometricStore: MockBiometricAuthStore(),
      inviteCoordinator: MockTeamInviteCoordinator()
    )
    viewModel.email = "user@example.com"
    viewModel.password = ""

    viewModel.login()

    #expect(viewModel.validationMessage == L10n.passwordRequired)
    #expect(viewModel.isLoading == false)
  }

  @Test
  func login_withUnverifiedEmail_showsVerificationFlow() async {
    let auth = MockAuthService()
    auth.loginHandler = { _, _ in
      LoginResponse(
        success: false,
        message: "verify",
        emailVerified: false,
        requiresVerification: true
      )
    }
    let pendingStore = InMemoryPendingCredentialsStore()
    let savedEmailStore = InMemorySavedLoginEmailStore()
    let viewModel = makeViewModel(
      auth: auth,
      savedEmailStore: savedEmailStore,
      pendingStore: pendingStore,
      biometricStore: MockBiometricAuthStore(),
      inviteCoordinator: MockTeamInviteCoordinator()
    )
    viewModel.email = "user@example.com"
    viewModel.password = "password123"

    viewModel.login()
    await AsyncTestSupport.waitUntil { viewModel.isLoading == false }

    #expect(viewModel.showEmailVerification)
    #expect(pendingStore.load()?.email == "user@example.com")
    #expect(savedEmailStore.load() == "user@example.com")
    #expect(auth.loginCallCount == 1)
  }

  @Test
  func login_withValidSession_doesNotSetValidationMessage() async {
    let auth = MockAuthService()
    auth.isAuthenticated = true
    auth.loginHandler = { _, _ in ViewModelTestFixtures.loginSuccessResponse }
    let viewModel = makeViewModel(
      auth: auth,
      savedEmailStore: InMemorySavedLoginEmailStore(),
      pendingStore: InMemoryPendingCredentialsStore(),
      biometricStore: MockBiometricAuthStore(),
      inviteCoordinator: MockTeamInviteCoordinator()
    )
    viewModel.email = "user@example.com"
    viewModel.password = "password123"

    viewModel.login()
    await AsyncTestSupport.waitUntil { viewModel.isLoading == false }

    #expect(viewModel.validationMessage == nil)
    #expect(viewModel.showEmailVerification == false)
  }

  @Test
  func login_whenAuthenticatedWithoutValidData_setsFailureMessage() async {
    let auth = MockAuthService()
    auth.loginHandler = { _, _ in ViewModelTestFixtures.loginSuccessResponse }
    let biometricStore = MockBiometricAuthStore()
    biometricStore.lastErrorMessage = "Biometric failed"
    let viewModel = makeViewModel(
      auth: auth,
      savedEmailStore: InMemorySavedLoginEmailStore(),
      pendingStore: InMemoryPendingCredentialsStore(),
      biometricStore: biometricStore,
      inviteCoordinator: MockTeamInviteCoordinator()
    )
    viewModel.email = "user@example.com"
    viewModel.password = "password123"

    viewModel.login()
    await AsyncTestSupport.waitUntil { viewModel.isLoading == false }

    #expect(viewModel.validationMessage == "Biometric failed")
  }
}
