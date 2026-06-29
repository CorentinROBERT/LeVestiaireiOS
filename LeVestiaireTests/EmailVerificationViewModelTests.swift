//
//  EmailVerificationViewModelTests.swift
//  LeVestiaireTests
//

import Foundation
import Testing
@testable import LeVestiaire

@MainActor
struct EmailVerificationViewModelTests {
  private func makeViewModel(
    email: String = "user@example.com",
    auth: MockAuthService,
    pendingStore: InMemoryPendingCredentialsStore,
    inviteCoordinator: MockTeamInviteCoordinator
  ) -> EmailVerificationViewModel {
    EmailVerificationViewModel(
      email: email,
      authService: auth,
      pendingCredentialsStore: pendingStore,
      teamInviteCoordinator: inviteCoordinator
    )
  }

  @Test
  func confirmVerification_whenEmailNotVerified_setsFeedback() async {
    let auth = MockAuthService()
    auth.checkEmailVerificationHandler = { _ in
      EmailVerificationResponse(
        success: true,
        data: EmailVerificationData(email: "user@example.com", emailVerified: false, isActive: nil)
      )
    }
    let viewModel = makeViewModel(
      auth: auth,
      pendingStore: InMemoryPendingCredentialsStore(),
      inviteCoordinator: MockTeamInviteCoordinator()
    )

    viewModel.confirmVerification()
    await AsyncTestSupport.waitUntil { viewModel.isCheckingVerification == false }

    #expect(viewModel.feedbackMessage == L10n.emailNotYetVerified)
  }

  @Test
  func confirmVerification_whenAlreadyAuthenticated_joinsPendingTeam() async {
    let auth = MockAuthService()
    auth.isAuthenticated = true
    auth.checkEmailVerificationHandler = { _ in
      EmailVerificationResponse(
        success: true,
        data: EmailVerificationData(email: "user@example.com", emailVerified: true, isActive: true)
      )
    }
    let inviteCoordinator = MockTeamInviteCoordinator()
    let viewModel = makeViewModel(
      auth: auth,
      pendingStore: InMemoryPendingCredentialsStore(),
      inviteCoordinator: inviteCoordinator
    )

    viewModel.confirmVerification()
    await AsyncTestSupport.waitUntil { viewModel.isCheckingVerification == false }

    #expect(inviteCoordinator.joinPendingTeamIfNeededCallCount == 1)
    #expect(viewModel.feedbackMessage == nil)
  }

  @Test
  func confirmVerification_withStoredCredentials_logsInAndClearsStore() async {
    let auth = MockAuthService()
    auth.isAuthenticated = true
    auth.checkEmailVerificationHandler = { _ in
      EmailVerificationResponse(
        success: true,
        data: EmailVerificationData(email: "user@example.com", emailVerified: true, isActive: true)
      )
    }
    auth.loginHandler = { _, _ in ViewModelTestFixtures.loginSuccessResponse }
    let pendingStore = InMemoryPendingCredentialsStore()
    pendingStore.save(email: "user@example.com", password: "password123")
    let inviteCoordinator = MockTeamInviteCoordinator()
    let viewModel = makeViewModel(
      auth: auth,
      pendingStore: pendingStore,
      inviteCoordinator: inviteCoordinator
    )

    auth.isAuthenticated = false
    viewModel.confirmVerification()
    await AsyncTestSupport.waitUntil { viewModel.isCheckingVerification == false }

    #expect(auth.loginCallCount == 1)
    #expect(pendingStore.load() == nil)
    #expect(inviteCoordinator.joinPendingTeamIfNeededCallCount == 1)
  }

  @Test
  func resendEmail_onSuccess_startsCooldown() async {
    let auth = MockAuthService()
    auth.resendVerificationEmailHandler = { _ in
      LoginResponse(success: true, message: "resent")
    }
    let viewModel = makeViewModel(
      auth: auth,
      pendingStore: InMemoryPendingCredentialsStore(),
      inviteCoordinator: MockTeamInviteCoordinator()
    )

    viewModel.resendEmail()
    await AsyncTestSupport.waitUntil { viewModel.isResending == false }

    #expect(viewModel.feedbackMessage != nil)
    #expect(viewModel.resendCooldownRemaining == 20)
    #expect(viewModel.canResendEmail == false)
  }
}
