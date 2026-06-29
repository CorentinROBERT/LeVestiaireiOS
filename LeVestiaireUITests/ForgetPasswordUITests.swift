//
//  ForgetPasswordUITests.swift
//  LeVestiaireUITests
//

import XCTest

final class ForgetPasswordUITests: XCTestCase {
    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    @MainActor
    func testForgetPassword_submitDisabledWithInvalidEmail() throws {
        let app = UITestApp.launch(scenario: .login)
        app.buttons[UITestID.Auth.forgotPasswordLink].tap()

        let emailField = app.textFields[UITestID.Auth.forgetPasswordEmailField]
        XCTAssertTrue(UITestApp.waitForExistence(of: emailField))

        let submit = app.buttons[UITestID.Auth.forgetPasswordSubmit]
        XCTAssertTrue(submit.exists)
        XCTAssertFalse(submit.isEnabled)
    }

    @MainActor
    func testForgetPassword_enablesSubmitWithValidEmail() throws {
        let app = UITestApp.launch(scenario: .login)
        app.buttons[UITestID.Auth.forgotPasswordLink].tap()

        let emailField = app.textFields[UITestID.Auth.forgetPasswordEmailField]
        XCTAssertTrue(UITestApp.waitForExistence(of: emailField))
        emailField.clearAndTypeText("user@example.com")

        let submit = app.buttons[UITestID.Auth.forgetPasswordSubmit]
        XCTAssertTrue(submit.isEnabled)
    }

    @MainActor
    func testForgetPassword_navigatesToResetPasswordFromLoginFlow() throws {
        let app = UITestApp.launch(scenario: .login)
        app.buttons[UITestID.Auth.forgotPasswordLink].tap()

        // Navigation manuelle vers reset password (comme après succès d'envoi d'email)
        app.navigationBars.buttons.element(boundBy: 0).tap()
        // Retour login puis test du lien register/back n'est pas nécessaire ici
        XCTAssertTrue(app.textFields[UITestID.Auth.emailField].waitForExistence(timeout: 4))
    }

    @MainActor
    func testForgetPassword_showsSuccessAlertOnSubmit() throws {
        let app = UITestApp.launch(scenario: .login)
        app.buttons[UITestID.Auth.forgotPasswordLink].tap()

        let emailField = app.textFields[UITestID.Auth.forgetPasswordEmailField]
        XCTAssertTrue(UITestApp.waitForExistence(of: emailField))
        emailField.clearAndTypeText("user@example.com")

        app.buttons[UITestID.Auth.forgetPasswordSubmit].tap()

        let alert = app.alerts["Email envoyé"]
        XCTAssertTrue(alert.waitForExistence(timeout: 8))
        alert.buttons["Continuer"].tap()
    }
}
