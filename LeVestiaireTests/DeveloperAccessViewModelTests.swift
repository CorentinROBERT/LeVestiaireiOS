//
//  DeveloperAccessViewModelTests.swift
//  LeVestiaireTests
//

import Testing
@testable import LeVestiaire

@MainActor
struct DeveloperAccessViewModelTests {
  @Test
  func registerTap_doesNotShowDialogBeforeThreshold() {
    let viewModel = DeveloperAccessViewModel()

    for _ in 0..<4 {
      viewModel.registerTap()
    }

    #expect(viewModel.showPasswordDialog == false)
  }

  @Test
  func registerTap_showsPasswordDialogAfterFiveTaps() {
    let viewModel = DeveloperAccessViewModel()

    for _ in 0..<5 {
      viewModel.registerTap()
    }

    #expect(viewModel.showPasswordDialog)
    #expect(viewModel.passwordInput.isEmpty)
  }

  @Test
  func validatePassword_opensDeveloperPageWithCorrectPassword() {
    let viewModel = DeveloperAccessViewModel()
    viewModel.passwordInput = "asdescopains"

    viewModel.validatePassword()

    #expect(viewModel.showDeveloperPage)
    #expect(viewModel.showPasswordDialog == false)
    #expect(viewModel.passwordInput.isEmpty)
  }

  @Test
  func validatePassword_showsErrorWithWrongPassword() {
    let viewModel = DeveloperAccessViewModel()
    viewModel.passwordInput = "wrong"

    viewModel.validatePassword()

    #expect(viewModel.showPasswordError)
    #expect(viewModel.showDeveloperPage == false)
  }

  @Test
  func cancelPasswordEntry_clearsDialogState() {
    let viewModel = DeveloperAccessViewModel()
    viewModel.showPasswordDialog = true
    viewModel.passwordInput = "test"

    viewModel.cancelPasswordEntry()

    #expect(viewModel.showPasswordDialog == false)
    #expect(viewModel.passwordInput.isEmpty)
  }
}
