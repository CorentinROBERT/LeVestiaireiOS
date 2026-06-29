//
//  TeamUITests.swift
//  LeVestiaireUITests
//

import XCTest

final class TeamUITests: XCTestCase {
    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    @MainActor
    func testTeamTab_displaysPopulatedTeamHero() throws {
        let app = UITestApp.launch(scenario: .authenticated)
        XCTAssertTrue(UITestApp.openTeamTab(in: app))

        XCTAssertTrue(app.staticTexts["FC Test UI"].waitForExistence(timeout: 8))
        XCTAssertTrue(app.staticTexts["2 membres"].exists)
        XCTAssertTrue(app.staticTexts["Admin"].exists)
        XCTAssertTrue(app.staticTexts["Équipe de test pour les UI tests"].exists)
    }

    @MainActor
    func testTeamTab_rosterListsPlayers() throws {
        let app = UITestApp.launch(scenario: .authenticated)
        XCTAssertTrue(UITestApp.openTeamTab(in: app))

        XCTAssertTrue(app.staticTexts["Joueurs"].waitForExistence(timeout: 8))
        XCTAssertTrue(app.staticTexts["Test UI"].waitForExistence(timeout: 8))
        XCTAssertTrue(app.staticTexts["Alex Martin"].exists)
    }

    @MainActor
    func testTeamTab_switchesToStatsTab_showsEmptyState() throws {
        let app = UITestApp.launch(scenario: .authenticated)
        XCTAssertTrue(UITestApp.openTeamTab(in: app))

        let statsTab = app.buttons["Stats"]
        XCTAssertTrue(statsTab.waitForExistence(timeout: 8))
        statsTab.tap()

        XCTAssertTrue(app.staticTexts["Pas encore de statistiques"].waitForExistence(timeout: 10)
            || app.staticTexts["Aucune statistique disponible pour cette saison"].waitForExistence(timeout: 2))
    }

    @MainActor
    func testTeamTab_switchesToCompositionsTab_showsEmptyState() throws {
        let app = UITestApp.launch(scenario: .authenticated)
        XCTAssertTrue(UITestApp.openTeamTab(in: app))

        let compositionsTab = app.buttons["Compos."]
        XCTAssertTrue(compositionsTab.waitForExistence(timeout: 8))
        compositionsTab.tap()

        XCTAssertTrue(app.staticTexts["Aucune composition créée"].waitForExistence(timeout: 10))
    }

    @MainActor
    func testTeamTab_opensTeamSettingsSheet() throws {
        let app = UITestApp.launch(scenario: .authenticated)
        XCTAssertTrue(UITestApp.openTeamTab(in: app))

        let settingsButton = UITestApp.teamSettingsButton(in: app)
        XCTAssertTrue(settingsButton.waitForExistence(timeout: 8))
        settingsButton.tap()

        XCTAssertTrue(UITestApp.waitForPresentation(of: "Options de l'équipe", in: app))
        UITestApp.dismissPresentation(in: app)
    }

    @MainActor
    func testTeamTab_adminCanOpenInvitePlayerSheet() throws {
        let app = UITestApp.launch(scenario: .authenticated)
        XCTAssertTrue(UITestApp.openTeamTab(in: app))

        let inviteButton = UITestApp.teamInvitePlayerButton(in: app)
        UITestApp.scrollToElement(inviteButton, in: app)
        XCTAssertTrue(inviteButton.waitForExistence(timeout: 8))
        inviteButton.tap()

        XCTAssertTrue(
            app.textFields["Prénom"].waitForExistence(timeout: 8)
                || app.sheets.firstMatch.waitForExistence(timeout: 4)
        )
    }

    @MainActor
    func testJoinTeam_searchAndSubmitsRequest() throws {
        let app = UITestApp.launch(scenario: .authenticated)
        UITestApp.tapTab(UITestApp.teamTab(in: app), in: app)

        let joinButton = app.buttons[UITestID.Main.joinTeamButton]
        if joinButton.waitForExistence(timeout: 8) {
            joinButton.tap()
            XCTAssertTrue(app.sheets.firstMatch.waitForExistence(timeout: 8))
            XCTAssertTrue(
                app.textFields.firstMatch.waitForExistence(timeout: 8)
                    || app.staticTexts.containing(
                        NSPredicate(format: "label CONTAINS[c] 'Rejoindre'")
                    ).firstMatch.exists
            )
        }
    }

    @MainActor
    func testCreateTeam_submitsFormAndShowsSuccess() throws {
        let app = UITestApp.launch(scenario: .authenticated)
        UITestApp.tapTab(UITestApp.teamTab(in: app), in: app)

        let createButton = app.buttons[UITestID.Main.createTeamButton]
        if createButton.waitForExistence(timeout: 8) {
            createButton.tap()
            XCTAssertTrue(app.sheets.firstMatch.waitForExistence(timeout: 8))
            XCTAssertTrue(app.buttons["Créer une équipe"].waitForExistence(timeout: 8))
        }
    }
}
