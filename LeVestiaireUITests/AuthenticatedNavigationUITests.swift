//
//  AuthenticatedNavigationUITests.swift
//  LeVestiaireUITests
//

import XCTest

final class AuthenticatedNavigationUITests: XCTestCase {
    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    @MainActor
    func testMainTabs_switchBetweenMatchesTeamAndProfile() throws {
        let app = UITestApp.launch(scenario: .authenticated)

        let matchesTab = UITestApp.matchesTab(in: app)
        let teamTab = UITestApp.teamTab(in: app)
        let profileTab = UITestApp.profileTab(in: app)

        XCTAssertTrue(matchesTab.waitForExistence(timeout: 10))
        UITestApp.tapTab(teamTab, in: app)
        XCTAssertTrue(app.navigationBars.staticTexts["Équipe"].waitForExistence(timeout: 8))

        UITestApp.tapTab(profileTab, in: app)
        XCTAssertTrue(app.navigationBars.staticTexts["Profile"].waitForExistence(timeout: 8)
            || app.navigationBars.staticTexts["Profil"].waitForExistence(timeout: 2))

        let logoutButton = UITestApp.profileLogoutButton(in: app)
        UITestApp.scrollToElement(logoutButton, in: app)
        XCTAssertTrue(logoutButton.waitForExistence(timeout: 8))

        UITestApp.tapTab(matchesTab, in: app)
        XCTAssertTrue(app.navigationBars.staticTexts["Matchs"].waitForExistence(timeout: 8))
    }

    @MainActor
    func testMatchesTab_showsCreateMatchAndFilterActions() throws {
        let app = UITestApp.launch(scenario: .authenticated)
        XCTAssertTrue(
            app.navigationBars.staticTexts["Matchs"].waitForExistence(timeout: 15)
                || app.otherElements[UITestID.Main.shell].waitForExistence(timeout: 4)
        )

        let createMatch = app.buttons[UITestID.Main.createMatchButton]
        let filterMatches = app.buttons[UITestID.Main.filterMatchesButton]

        XCTAssertTrue(UITestApp.waitForFixtureMatchList(in: app))
        XCTAssertTrue(createMatch.waitForExistence(timeout: 8))
        XCTAssertTrue(filterMatches.exists)

        filterMatches.tap()
        XCTAssertTrue(UITestApp.waitForPresentation(of: "Filtrer les matchs", in: app))
        UITestApp.dismissPresentation(in: app)

        createMatch.tap()
        XCTAssertTrue(UITestApp.waitForPresentation(of: "Nouveau match", in: app))
    }

    @MainActor
    func testTeamTab_showsJoinAndCreateTeamActionsInHero() throws {
        let app = UITestApp.launch(scenario: .authenticated)
        UITestApp.tapTab(UITestApp.teamTab(in: app), in: app)
        XCTAssertTrue(app.navigationBars.staticTexts["Équipe"].waitForExistence(timeout: 10))

        let joinTeam = app.buttons[UITestID.Main.joinTeamButton]
        let createTeam = app.buttons[UITestID.Main.createTeamButton]

        if joinTeam.waitForExistence(timeout: 8) {
            joinTeam.tap()
            XCTAssertTrue(app.sheets.firstMatch.waitForExistence(timeout: 4))
            app.swipeDown()
        }

        if createTeam.waitForExistence(timeout: 4) {
            createTeam.tap()
            XCTAssertTrue(app.sheets.firstMatch.waitForExistence(timeout: 4))
        }
    }

    @MainActor
    func testProfileTab_opensSettingsSheet() throws {
        let app = UITestApp.launch(scenario: .authenticated)
        UITestApp.tapTab(UITestApp.profileTab(in: app), in: app)

        let settingsButton = UITestApp.profileSettingsButton(in: app)
        UITestApp.scrollToElement(settingsButton, in: app, maxSwipes: 10)
        XCTAssertTrue(settingsButton.waitForExistence(timeout: 12))
        settingsButton.tap()

        XCTAssertTrue(UITestApp.waitForPresentation(of: "Connexion biométrique", in: app))
    }

    @MainActor
    func testNotifications_opensNotificationCenter() throws {
        let app = UITestApp.launch(scenario: .authenticated)

        let notificationsButton = UITestApp.notificationsButton(in: app)
        XCTAssertTrue(notificationsButton.waitForExistence(timeout: 12))
        notificationsButton.tap()

        XCTAssertTrue(UITestApp.waitForPresentation(of: "Notifications", in: app, timeout: 12))
        UITestApp.dismissPresentation(in: app)
    }

    @MainActor
    func testNotifications_displaysStubbedNotificationItem() throws {
        let app = UITestApp.launch(
            scenario: .authenticated,
            additionalArguments: ["-UITestPopulatedNotifications"],
            additionalEnvironment: ["UITEST_POPULATED_NOTIFICATIONS": "1"]
        )

        XCTAssertTrue(UITestApp.waitForMainShell(in: app))
        XCTAssertTrue(UITestApp.notificationsButton(in: app).waitForExistence(timeout: 12))
    }

    @MainActor
    func testProfile_displaysAuthenticatedUserIdentity() throws {
        let app = UITestApp.launch(scenario: .authenticated)
        UITestApp.tapTab(UITestApp.profileTab(in: app), in: app)

        XCTAssertTrue(app.staticTexts["Test"].waitForExistence(timeout: 10))
        XCTAssertTrue(app.staticTexts["UI"].exists)
        XCTAssertTrue(app.staticTexts["uitest@levestaire.test"].exists)
    }

    @MainActor
    func testProfile_showsLogoutConfirmation() throws {
        let app = UITestApp.launch(scenario: .authenticated)
        UITestApp.tapTab(UITestApp.profileTab(in: app), in: app)

        let logoutButton = UITestApp.profileLogoutButton(in: app)
        UITestApp.scrollToElement(logoutButton, in: app)
        XCTAssertTrue(logoutButton.waitForExistence(timeout: 10))
        logoutButton.tap()

        let alert = app.alerts.firstMatch
        XCTAssertTrue(alert.waitForExistence(timeout: 4))
        alert.buttons["Annuler"].tap()
    }

    @MainActor
    func testProfile_logoutReturnsToLogin() throws {
        let app = UITestApp.launch(scenario: .authenticated)
        UITestApp.tapTab(UITestApp.profileTab(in: app), in: app)

        XCTAssertTrue(
            UITestApp.confirmLogout(in: app),
            "La déconnexion doit ramener à l'écran de connexion"
        )
    }
}
