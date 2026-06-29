//
//  ResetPasswordViewModelTests.swift
//  LeVestiaireTests
//

import Foundation
import Testing
@testable import LeVestiaire

@MainActor
struct ResetPasswordViewModelTests {
  @Test
  func canSubmit_requiresFieldsAndNotLoading() {
    let viewModel = ResetPasswordViewModel(
      resetToken: "token-123",
      authService: MockAuthService()
    )
    viewModel.updateVerificationCode("12345678")
    viewModel.password = "password123"
    viewModel.confirmPassword = "password123"

    #expect(viewModel.canSubmit)
  }

  @Test
  func updateVerificationCode_filtersNonDigitsAndLimitsLength() {
    let viewModel = ResetPasswordViewModel(
      resetToken: nil,
      authService: MockAuthService()
    )

    viewModel.updateVerificationCode("12ab34")

    #expect(viewModel.verificationCode == "1234")
  }

  @Test
  func resetPassword_withMismatchedPasswords_setsValidationMessage() {
    let viewModel = ResetPasswordViewModel(
      resetToken: "token-123",
      authService: MockAuthService()
    )
    viewModel.updateVerificationCode("12345678")
    viewModel.password = "password123"
    viewModel.confirmPassword = "different"

    viewModel.resetPassword()

    #expect(viewModel.validationMessage == L10n.passwordsDoNotMatch)
  }

  @Test
  func resetPassword_withShortPassword_setsValidationMessage() {
    let viewModel = ResetPasswordViewModel(
      resetToken: "token-123",
      authService: MockAuthService()
    )
    viewModel.updateVerificationCode("12345678")
    viewModel.password = "short"
    viewModel.confirmPassword = "short"

    viewModel.resetPassword()

    #expect(viewModel.validationMessage == L10n.passwordMin8Characters)
  }

  @Test
  func resetPassword_withIncompleteForm_setsValidationMessage() {
    let viewModel = ResetPasswordViewModel(
      resetToken: nil,
      authService: MockAuthService()
    )
    viewModel.password = "password123"
    viewModel.confirmPassword = "password123"

    viewModel.resetPassword()

    #expect(viewModel.validationMessage == L10n.fillAllFields)
  }

  @Test
  func resetPassword_onSuccess_setsSuccessMessage() async {
    let auth = MockAuthService()
    auth.confirmPasswordResetHandler = { token, password in
      #expect(token == "token-123")
      #expect(password == "password123")
      return PasswordResetResponse(success: true, message: "password-updated")
    }
    let viewModel = ResetPasswordViewModel(resetToken: "token-123", authService: auth)
    viewModel.updateVerificationCode("12345678")
    viewModel.password = "password123"
    viewModel.confirmPassword = "password123"

    viewModel.resetPassword()
    await AsyncTestSupport.waitUntil { viewModel.isLoading == false }

    #expect(viewModel.successMessage != nil)
    #expect(viewModel.validationMessage == nil)
  }

  @Test
  func resetPassword_usesVerificationCodeWhenTokenMissing() async {
    let auth = MockAuthService()
    auth.confirmPasswordResetHandler = { token, _ in
      #expect(token == "12345678")
      return PasswordResetResponse(success: true, message: "ok")
    }
    let viewModel = ResetPasswordViewModel(resetToken: nil, authService: auth)
    viewModel.updateVerificationCode("12345678")
    viewModel.password = "password123"
    viewModel.confirmPassword = "password123"

    viewModel.resetPassword()
    await AsyncTestSupport.waitUntil { viewModel.isLoading == false }

    #expect(viewModel.successMessage != nil)
  }
}
