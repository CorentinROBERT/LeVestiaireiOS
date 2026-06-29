//
//  RegisterUITests.swift
//  LeVestiaireUITests
//

import XCTest

final class RegisterUITests: XCTestCase {
    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    @MainActor
    private func openRegister(from app: XCUIApplication) {
        let createAccount = app.buttons[UITestID.Auth.createAccountLink]
        XCTAssertTrue(UITestApp.waitForExistence(of: createAccount))
        createAccount.tap()
        XCTAssertTrue(app.textFields[UITestID.Register.emailField].waitForExistence(timeout: 4))
    }

    @MainActor
    func testRegister_submitDisabledUntilLegalTermsAccepted() throws {
        let app = UITestApp.launch(scenario: .login)
        openRegister(from: app)

        let submit = app.buttons[UITestID.Register.submitButton]
        XCTAssertTrue(submit.exists)
        XCTAssertFalse(submit.isEnabled)
    }

    @MainActor
    func testRegister_fillsFormAndEnablesSubmitAfterLegalAcceptance() throws {
        let app = UITestApp.launch(scenario: .login)
        openRegister(from: app)

        app.textFields[UITestID.Register.lastNameField].clearAndTypeText("Martin")
        app.textFields[UITestID.Register.firstNameField].clearAndTypeText("Alice")
        app.textFields[UITestID.Register.emailField].clearAndTypeText("alice@example.com")
        UITestApp.registerPasswordField(UITestID.Register.passwordField, in: app).clearAndTypeText("password123")
        UITestApp.registerPasswordField(UITestID.Register.confirmPasswordField, in: app).clearAndTypeText("password123")

        let legalToggle = app.switches[UITestID.Register.legalToggle]
        if legalToggle.waitForExistence(timeout: 2) {
            if legalToggle.value as? String == "0" {
                legalToggle.tap()
            }
        }

        let submit = app.buttons[UITestID.Register.submitButton]
        XCTAssertTrue(submit.waitForExistence(timeout: 2))
        XCTAssertTrue(submit.isEnabled)
    }

    @MainActor
    func testRegister_showsValidationWhenSubmittingIncompleteForm() throws {
        let app = UITestApp.launch(scenario: .login)
        openRegister(from: app)

        app.textFields[UITestID.Register.lastNameField].clearAndTypeText("Martin")
        app.textFields[UITestID.Register.firstNameField].clearAndTypeText("Alice")
        app.textFields[UITestID.Register.emailField].clearAndTypeText("invalid-email")
        UITestApp.registerPasswordField(UITestID.Register.passwordField, in: app).clearAndTypeText("password123")
        UITestApp.registerPasswordField(UITestID.Register.confirmPasswordField, in: app).clearAndTypeText("password123")

        let legalToggle = app.switches[UITestID.Register.legalToggle]
        if legalToggle.waitForExistence(timeout: 2), legalToggle.value as? String == "0" {
            legalToggle.tap()
        }

        app.buttons[UITestID.Register.submitButton].tap()

        let alert = app.alerts.firstMatch
        XCTAssertTrue(alert.waitForExistence(timeout: 4))
        alert.buttons.firstMatch.tap()
    }

    @MainActor
    func testRegister_submitsAndShowsEmailVerification() throws {
        let app = UITestApp.launch(scenario: .login)
        openRegister(from: app)
        let email = "uitest-register@example.com"
        UITestApp.fillRegisterFormAndAcceptLegal(in: app, email: email)

        let submit = app.buttons[UITestID.Register.submitButton]
        XCTAssertTrue(submit.isEnabled)
        submit.tap()

        let alert = app.alerts["Inscription"]
        if alert.waitForExistence(timeout: 8) {
            let message = alert.staticTexts.element(boundBy: 1).label
            alert.buttons.firstMatch.tap()
            XCTFail("L'inscription a échoué avec l'alerte : \(message)")
        }

        let confirmButton = app.buttons[UITestID.EmailVerification.confirmButton]
        XCTAssertTrue(
            confirmButton.waitForExistence(timeout: 20)
                || app.navigationBars["Vérification"].waitForExistence(timeout: 4),
            "L'inscription stubée doit mener à l'écran de vérification email"
        )
    }
}
