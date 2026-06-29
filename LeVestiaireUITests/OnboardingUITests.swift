//
//  OnboardingUITests.swift
//  LeVestiaireUITests
//

import XCTest

final class OnboardingUITests: XCTestCase {
    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    @MainActor
    func testLanding_advancesThroughCarouselToLogin() throws {
        let app = UITestApp.launch(scenario: .landing)
        let primaryButton = app.buttons[UITestID.Onboarding.primaryButton]
        XCTAssertTrue(UITestApp.waitForExistence(of: primaryButton))

        for _ in 0..<3 {
            primaryButton.tap()
        }

        primaryButton.tap()
        XCTAssertTrue(app.textFields[UITestID.Auth.emailField].waitForExistence(timeout: 6))
    }
}
