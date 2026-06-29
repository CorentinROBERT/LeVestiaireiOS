//
//  ForgetPasswordViewModelTests.swift
//  LeVestiaireTests
//

import Foundation
import Testing
@testable import LeVestiaire

@MainActor
struct ForgetPasswordViewModelTests {
  @Test
  func canSubmit_requiresEmailAndNotLoading() {
    let viewModel = ForgetPasswordViewModel(authService: MockAuthService())
    viewModel.email = "user@example.com"

    #expect(viewModel.canSubmit)
  }

  @Test
  func submit_withEmptyEmail_setsValidationMessage() {
    let viewModel = ForgetPasswordViewModel(authService: MockAuthService())
    viewModel.email = "   "

    viewModel.submit()

    #expect(viewModel.validationMessage == L10n.pleaseEnterYourEmail)
    #expect(viewModel.successMessage == nil)
  }

  @Test
  func submit_withInvalidEmail_setsValidationMessage() {
    let viewModel = ForgetPasswordViewModel(authService: MockAuthService())
    viewModel.email = "invalid-email"

    viewModel.submit()

    #expect(viewModel.validationMessage == L10n.emailInvalid)
  }

  @Test
  func submit_onSuccess_setsSuccessMessage() async {
    let auth = MockAuthService()
    auth.requestPasswordResetHandler = { _ in
      PasswordResetResponse(success: true, message: "email-sent")
    }
    let viewModel = ForgetPasswordViewModel(authService: auth)
    viewModel.email = "user@example.com"

    viewModel.submit()
    await AsyncTestSupport.waitUntil { viewModel.isLoading == false }

    #expect(viewModel.successMessage != nil)
    #expect(viewModel.validationMessage == nil)
  }
}
