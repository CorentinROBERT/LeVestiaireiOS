//
//  LoginUITests.swift
//  LeVestiaireUITests
//

import XCTest

final class LoginUITests: XCTestCase {
    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    @MainActor
    func testLogin_showsValidationAlertWhenFieldsEmpty() throws {
        let app = UITestApp.launch(scenario: .login)
        let loginButton = app.buttons[UITestID.Auth.loginButton]
        XCTAssertTrue(UITestApp.waitForExistence(of: loginButton))

        loginButton.tap()

        let alert = app.alerts.firstMatch
        XCTAssertTrue(alert.waitForExistence(timeout: 4))
        alert.buttons.firstMatch.tap()
    }

    @MainActor
    func testLogin_navigatesToRegister() throws {
        let app = UITestApp.launch(scenario: .login)
        let createAccount = app.buttons[UITestID.Auth.createAccountLink]
        XCTAssertTrue(UITestApp.waitForExistence(of: createAccount))

        createAccount.tap()

        XCTAssertTrue(app.textFields[UITestID.Register.emailField].waitForExistence(timeout: 4))
        XCTAssertTrue(app.navigationBars.element(boundBy: 0).exists)
    }

    @MainActor
    func testLogin_navigatesToForgetPassword() throws {
        let app = UITestApp.launch(scenario: .login)
        let forgotPassword = app.buttons[UITestID.Auth.forgotPasswordLink]
        XCTAssertTrue(UITestApp.waitForExistence(of: forgotPassword))

        forgotPassword.tap()

        XCTAssertTrue(app.textFields[UITestID.Auth.forgetPasswordEmailField].waitForExistence(timeout: 4))
    }

    @MainActor
    func testLogin_fillsCredentialsAndSubmits() throws {
        let app = UITestApp.launch(scenario: .login)
        let emailField = app.textFields[UITestID.Auth.emailField]
        let passwordField = app.secureTextFields[UITestID.Auth.passwordField]
        XCTAssertTrue(UITestApp.waitForExistence(of: emailField))

        emailField.clearAndTypeText("test@example.com")
        passwordField.clearAndTypeText("password123")
        UITestApp.dismissKeyboard(in: app)
        app.buttons[UITestID.Auth.loginButton].tap()

        // Sans backend réel : soit une alerte d'erreur, soit une navigation — l'écran ne doit pas crasher.
        XCTAssertTrue(app.exists)
    }

    @MainActor
    func testLogin_validCredentialsReachMainShell() throws {
        let app = UITestApp.launch(scenario: .login)
        UITestApp.fillLoginAndSubmit(in: app)
        XCTAssertTrue(
            UITestApp.waitForMainShell(in: app, timeout: 20),
            "La connexion stubée doit mener au shell principal"
        )
    }
}
