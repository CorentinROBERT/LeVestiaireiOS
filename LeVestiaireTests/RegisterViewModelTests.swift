//
//  RegisterViewModelTests.swift
//  LeVestiaireTests
//

import Foundation
import Testing
@testable import LeVestiaire

@MainActor
struct RegisterViewModelTests {
  private func makeViewModel(
    auth: MockAuthService,
    pendingStore: InMemoryPendingCredentialsStore,
    inviteCoordinator: MockTeamInviteCoordinator
  ) -> RegisterViewModel {
    RegisterViewModel(
      authService: auth,
      pendingCredentialsStore: pendingStore,
      teamInviteCoordinator: inviteCoordinator
    )
  }

  private func fillValidForm(_ viewModel: RegisterViewModel, birthDate: Date? = nil) {
    viewModel.firstName = "Alice"
    viewModel.lastName = "Martin"
    viewModel.email = "alice@example.com"
    viewModel.password = "password123"
    viewModel.confirmPassword = "password123"
    viewModel.hasAcceptedLegalTerms = true
    viewModel.birthDate = birthDate
  }

  @Test
  func canSubmit_isFalseWhenFormIncomplete() {
    let viewModel = makeViewModel(
      auth: MockAuthService(),
      pendingStore: InMemoryPendingCredentialsStore(),
      inviteCoordinator: MockTeamInviteCoordinator()
    )
    fillValidForm(viewModel)
    viewModel.hasAcceptedLegalTerms = false

    #expect(viewModel.canSubmit == false)
  }

  @Test
  func createAccount_withInvalidEmail_setsValidationMessage() {
    let viewModel = makeViewModel(
      auth: MockAuthService(),
      pendingStore: InMemoryPendingCredentialsStore(),
      inviteCoordinator: MockTeamInviteCoordinator()
    )
    fillValidForm(viewModel)
    viewModel.email = "not-valid"

    viewModel.createAccount()

    #expect(viewModel.validationMessage == L10n.emailInvalid)
    #expect(viewModel.isLoading == false)
  }

  @Test
  func createAccount_withMismatchedPasswords_setsValidationMessage() {
    let viewModel = makeViewModel(
      auth: MockAuthService(),
      pendingStore: InMemoryPendingCredentialsStore(),
      inviteCoordinator: MockTeamInviteCoordinator()
    )
    fillValidForm(viewModel)
    viewModel.confirmPassword = "different"

    viewModel.createAccount()

    #expect(viewModel.validationMessage == L10n.passwordsDoNotMatch)
  }

  @Test
  func createAccount_withShortPassword_setsValidationMessage() {
    let viewModel = makeViewModel(
      auth: MockAuthService(),
      pendingStore: InMemoryPendingCredentialsStore(),
      inviteCoordinator: MockTeamInviteCoordinator()
    )
    fillValidForm(viewModel)
    viewModel.password = "short"
    viewModel.confirmPassword = "short"

    viewModel.createAccount()

    #expect(viewModel.validationMessage == L10n.passwordMin8Characters)
  }

  @Test
  func createAccount_onSuccess_showsEmailVerification() async {
    let auth = MockAuthService()
    auth.registerHandler = { _, _, _, _, _, _, _ in
      LoginResponse(success: true, message: "created")
    }
    let pendingStore = InMemoryPendingCredentialsStore()
    let inviteCoordinator = MockTeamInviteCoordinator()
    inviteCoordinator.pendingCode = "TEAM01"
    let viewModel = makeViewModel(
      auth: auth,
      pendingStore: pendingStore,
      inviteCoordinator: inviteCoordinator
    )
    fillValidForm(viewModel)

    viewModel.createAccount()
    await AsyncTestSupport.waitUntil { viewModel.isLoading == false }

    #expect(viewModel.showEmailVerification)
    #expect(pendingStore.load()?.email == "alice@example.com")
    #expect(auth.registerCallCount == 1)
    #expect(auth.lastRegisterInviteCode == "TEAM01")
  }

  @Test
  func createAccount_withoutBirthDate_succeeds() async {
    let auth = MockAuthService()
    auth.registerHandler = { _, _, _, _, birthDate, _, _ in
      #expect(birthDate == nil)
      return LoginResponse(success: true, message: "created")
    }
    let viewModel = makeViewModel(
      auth: auth,
      pendingStore: InMemoryPendingCredentialsStore(),
      inviteCoordinator: MockTeamInviteCoordinator()
    )
    fillValidForm(viewModel)

    viewModel.createAccount()
    await AsyncTestSupport.waitUntil { viewModel.isLoading == false }

    #expect(viewModel.showEmailVerification)
    #expect(auth.registerCallCount == 1)
  }
}
