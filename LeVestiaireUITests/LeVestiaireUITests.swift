//
//  LeVestiaireUITests.swift
//  LeVestiaireUITests
//

import XCTest

final class LeVestiaireUITests: XCTestCase {
    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    @MainActor
    func testLoginScreen_launchesInLoginScenario() throws {
        let app = UITestApp.launch(scenario: .login)
        XCTAssertTrue(app.textFields[UITestID.Auth.emailField].waitForExistence(timeout: 8))
        XCTAssertTrue(app.secureTextFields[UITestID.Auth.passwordField].exists)
        XCTAssertTrue(app.buttons[UITestID.Auth.loginButton].exists)
    }
}
