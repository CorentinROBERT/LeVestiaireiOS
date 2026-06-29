//
//  ResetPasswordUITests.swift
//  LeVestiaireUITests
//

import XCTest

final class ResetPasswordUITests: XCTestCase {
    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    private func passwordField(in app: XCUIApplication) -> XCUIElement {
        let secure = app.secureTextFields[UITestID.Auth.resetPasswordField]
        if secure.exists { return secure }
        return app.textFields[UITestID.Auth.resetPasswordField]
    }

    private func confirmPasswordField(in app: XCUIApplication) -> XCUIElement {
        let secure = app.secureTextFields[UITestID.Auth.resetPasswordConfirmField]
        if secure.exists { return secure }
        return app.textFields[UITestID.Auth.resetPasswordConfirmField]
    }

    @MainActor
    func testResetPasswordScreen_isDisplayedFromLoginFlow() throws {
        let app = UITestApp.launch(
            scenario: .login,
            additionalArguments: ["-UITestOpenResetPassword"]
        )

        XCTAssertTrue(app.navigationBars["Réinitialisation"].waitForExistence(timeout: 8))
        XCTAssertTrue(passwordField(in: app).exists)
        XCTAssertTrue(confirmPasswordField(in: app).exists)
    }

    @MainActor
    func testResetPassword_showsValidationWhenPasswordsDoNotMatch() throws {
        let app = UITestApp.launch(
            scenario: .login,
            additionalArguments: ["-UITestOpenResetPassword"]
        )

        let verificationField = app.textFields.element(boundBy: 0)
        let passwordField = passwordField(in: app)
        let confirmField = confirmPasswordField(in: app)
        let submit = app.buttons[UITestID.Auth.resetPasswordSubmit]

        XCTAssertTrue(verificationField.waitForExistence(timeout: 8))
        verificationField.tap()
        verificationField.typeText("123456")

        passwordField.tap()
        passwordField.typeText("Password1!")
        confirmField.tap()
        confirmField.typeText("Password2!")
        UITestApp.dismissKeyboard(in: app)

        XCTAssertTrue(submit.isEnabled)
        submit.tap()
        XCTAssertTrue(
            app.staticTexts["Les mots de passe ne correspondent pas"].waitForExistence(timeout: 4)
        )
    }
}
