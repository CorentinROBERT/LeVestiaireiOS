//
//  EmailVerificationViewModelTests.swift
//  LeVestiaireTests
//

import Foundation
import Testing
@testable import LeVestiaire

@MainActor
@Suite(.serialized)
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

    await viewModel.performConfirmVerification()

    #expect(viewModel.feedbackMessage == L10n.emailNotYetVerified)
    #expect(viewModel.isCheckingVerification == false)
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

    await viewModel.performConfirmVerification()

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
    await viewModel.performConfirmVerification()

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

    await viewModel.performResendEmail()

    #expect(viewModel.feedbackMessage != nil)
    #expect(viewModel.resendCooldownRemaining > 0)
    #expect(viewModel.resendCooldownRemaining <= 20)
    #expect(viewModel.canResendEmail == false)
  }
}
