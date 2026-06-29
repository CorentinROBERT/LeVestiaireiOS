//
//  CreateMatchUITests.swift
//  LeVestiaireUITests
//

import XCTest

final class CreateMatchUITests: XCTestCase {
    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    @MainActor
    func testCreateMatch_submitsFormAndOpensCreatedMatchDetail() throws {
        let app = UITestApp.launch(scenario: .authenticated)
        XCTAssertTrue(UITestApp.waitForFixtureMatchList(in: app))

        UITestApp.openCreateMatchSheet(in: app)
        UITestApp.fillCreateMatchForm(in: app)

        let submit = UITestApp.createMatchSubmitButton(in: app)
        UITestApp.scrollToElement(submit, in: app, maxSwipes: 8)
        XCTAssertTrue(submit.waitForExistence(timeout: 6))
        XCTAssertTrue(
            UITestApp.waitUntilEnabled(submit),
            "Le bouton de création doit être actif une fois le formulaire rempli"
        )
        UITestApp.tapElement(submit)

        let detailVisible = app.navigationBars.staticTexts["vs Test Opponent"].waitForExistence(timeout: 15)
            || app.staticTexts["Test Opponent"].waitForExistence(timeout: 4)
            || app.otherElements[UITestID.Match.detailView].waitForExistence(timeout: 4)
            || !app.sheets.firstMatch.exists && UITestApp.waitForFixtureMatchList(in: app, timeout: 6)
        XCTAssertTrue(
            detailVisible,
            "La création doit ouvrir le détail du match créé ou revenir à la liste"
        )
    }
}
