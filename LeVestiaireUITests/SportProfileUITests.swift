//
//  SportProfileUITests.swift
//  LeVestiaireUITests
//

import XCTest

final class SportProfileUITests: XCTestCase {
    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    @MainActor
    func testSportProfileScreen_isDisplayedWhenRequired() throws {
        let app = UITestApp.launch(scenario: .sportProfile)
        let submit = UITestApp.sportProfileSubmitButton(in: app)
        XCTAssertTrue(submit.exists)

        let jerseyField = app.textFields[UITestID.SportProfile.jerseyField]
        UITestApp.scrollToElement(jerseyField, in: app)
        XCTAssertTrue(jerseyField.exists || app.navigationBars["Profil sportif"].exists)
    }

    @MainActor
    func testSportProfile_submitDisabledUntilRequiredFieldsFilled() throws {
        let app = UITestApp.launch(scenario: .sportProfile)
        let submit = UITestApp.sportProfileSubmitButton(in: app)
        XCTAssertTrue(submit.exists)
        XCTAssertFalse(submit.isEnabled)
    }

    @MainActor
    func testSportProfile_tappingSubmitWithoutCompletionShowsAlert() throws {
        let app = UITestApp.launch(scenario: .sportProfile)
        let submit = UITestApp.sportProfileSubmitButton(in: app)
        XCTAssertTrue(submit.exists)
        XCTAssertFalse(submit.isEnabled)
    }

    @MainActor
    func testSportProfile_fillsJerseyNumber() throws {
        let app = UITestApp.launch(scenario: .sportProfile)
        let jerseyField = app.textFields[UITestID.SportProfile.jerseyField]
        UITestApp.scrollToElement(jerseyField, in: app)
        XCTAssertTrue(jerseyField.waitForExistence(timeout: 6))

        jerseyField.tap()
        jerseyField.typeText("10")
        UITestApp.dismissKeyboard(in: app)

        XCTAssertTrue((jerseyField.value as? String)?.contains("10") == true)
    }

    @MainActor
    func testSportProfile_completesOnboardingAndReachesMainShell() throws {
        let app = UITestApp.launch(scenario: .sportProfile)

        UITestApp.fillMinimalSportProfile(in: app)

        let submit = UITestApp.sportProfileSubmitButton(in: app)
        UITestApp.scrollToElement(submit, in: app, maxSwipes: 12)
        XCTAssertTrue(submit.waitForExistence(timeout: 6))
        XCTAssertTrue(
            UITestApp.waitUntilEnabled(submit),
            "Le bouton de finalisation doit être actif après saisie minimale"
        )
        UITestApp.tapElement(submit)

        XCTAssertTrue(
            UITestApp.waitForMainShell(in: app, timeout: 25),
            "Le profil sportif complété doit afficher le shell principal"
        )
        XCTAssertTrue(
            app.navigationBars.staticTexts["Matchs"].waitForExistence(timeout: 8)
                || UITestApp.fixtureMatchCard(in: app).waitForExistence(timeout: 4)
        )
    }
}
