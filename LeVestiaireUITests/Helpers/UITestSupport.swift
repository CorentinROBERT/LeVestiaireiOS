//
//  UITestIdentifiers.swift
//  LeVestiaireUITests
//

import Foundation

enum UITestID {
    enum Onboarding {
        static let primaryButton = "onboarding.primaryButton"
    }

    enum Auth {
        static let emailField = "auth.email"
        static let passwordField = "auth.password"
        static let loginButton = "auth.login"
        static let forgotPasswordLink = "auth.forgotPassword"
        static let createAccountLink = "auth.createAccount"
        static let forgetPasswordEmailField = "auth.forgetPassword.email"
        static let forgetPasswordSubmit = "auth.forgetPassword.submit"
        static let resetPasswordField = "auth.resetPassword.password"
        static let resetPasswordConfirmField = "auth.resetPassword.confirm"
        static let resetPasswordSubmit = "auth.resetPassword.submit"
    }

    enum Register {
        static let lastNameField = "register.lastName"
        static let firstNameField = "register.firstName"
        static let emailField = "register.email"
        static let passwordField = "register.password"
        static let confirmPasswordField = "register.confirmPassword"
        static let legalToggle = "register.legalToggle"
        static let submitButton = "register.submit"
    }

    enum EmailVerification {
        static let confirmButton = "emailVerification.confirm"
    }

    enum SportProfile {
        static let jerseyField = "sportProfile.jersey"
        static let submitButton = "sportProfile.submit"
    }

    enum Tab {
        static let matches = "tab.matches"
        static let team = "tab.team"
        static let profile = "tab.profile"
    }

    enum Main {
        static let shell = "main.shell"
        static let notificationsButton = "main.notifications"
        static let createMatchButton = "main.createMatch"
        static let filterMatchesButton = "main.filterMatches"
        static let joinTeamButton = "team.join"
        static let createTeamButton = "team.create"
        static let profileSettingsButton = "profile.settings"
        static let profileLogoutButton = "profile.logout"
    }

    enum Match {
        static let fixtureMatchId = "ui-test-match-1"
        static let finishedFixtureMatchId = "ui-test-match-finished"
        static let prepareFixtureMatchId = "ui-test-match-prepare"
        static let detailView = "match.detail"
        static let tabPicker = "match.detail.tabs"

        static func listingCard(_ matchId: String) -> String {
            "match.listing.\(matchId)"
        }
    }

    enum Team {
        static let shell = "team.shell"
        static let settingsButton = "team.settings"
    }
}

enum UITestScenario: String {
    case landing
    case login
    case authenticated
    case sportProfile
}

enum UITestApp {
    static func launch(
        scenario: UITestScenario,
        additionalArguments: [String] = [],
        additionalEnvironment: [String: String] = [:]
    ) -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments = [
            "-UITesting",
            "-UITestScenario",
            scenario.rawValue,
            "-UITestResetState",
        ] + additionalArguments
        app.launchEnvironment = [
            "UITESTING": "1",
            "UITEST_SCENARIO": scenario.rawValue,
        ].merging(additionalEnvironment) { _, new in new }
        app.launch()

        switch scenario {
        case .landing:
            _ = app.buttons[UITestID.Onboarding.primaryButton].waitForExistence(timeout: 10)
        case .login:
            if additionalArguments.contains("-UITestOpenResetPassword") {
                _ = app.navigationBars["Réinitialisation"].waitForExistence(timeout: 12)
            } else {
                _ = app.textFields[UITestID.Auth.emailField].waitForExistence(timeout: 12)
            }
        case .authenticated:
            XCTAssertTrue(waitForMainShell(in: app), "Le shell authentifié ne s'est pas affiché")
        case .sportProfile:
            _ = waitForSportProfile(in: app)
        }

        return app
    }

    @discardableResult
    static func waitForMainShell(in app: XCUIApplication, timeout: TimeInterval = 20) -> Bool {
        let shell = app.otherElements[UITestID.Main.shell]
        if shell.waitForExistence(timeout: timeout) {
            return true
        }

        let deadline = Date().addingTimeInterval(4)
        while Date() < deadline {
            if app.buttons[UITestID.Main.notificationsButton].exists { return true }
            if app.navigationBars.staticTexts["Matchs"].exists { return true }
            if app.tabBars.firstMatch.exists { return true }
            RunLoop.current.run(until: Date().addingTimeInterval(0.25))
        }
        return false
    }

    @discardableResult
    private static func waitForSportProfile(in app: XCUIApplication, timeout: TimeInterval = 20) -> Bool {
        let deadline = Date().addingTimeInterval(timeout)
        while Date() < deadline {
            if sportProfileSubmitButton(in: app).exists { return true }
            if app.navigationBars["Profil sportif"].exists { return true }
            RunLoop.current.run(until: Date().addingTimeInterval(0.25))
        }
        return false
    }

    static func sportProfileSubmitButton(in app: XCUIApplication) -> XCUIElement {
        let byID = app.buttons[UITestID.SportProfile.submitButton]
        if byID.exists { return byID }

        for label in ["Enregistrer", "Finaliser mon profil"] {
            let button = app.buttons[label]
            if button.exists { return button }
        }

        return app.buttons["Finaliser mon profil"]
    }

    static func sportProfileEditButton(in app: XCUIApplication) -> XCUIElement {
        let byLabel = app.buttons["Modifier le profile sportif"]
        if byLabel.exists { return byLabel }
        return app.buttons.matching(
            NSPredicate(format: "label CONTAINS[c] 'Modifier le profile'")
        ).firstMatch
    }

    @discardableResult
    static func waitForProfileTab(in app: XCUIApplication, timeout: TimeInterval = 10) -> Bool {
        app.navigationBars.staticTexts["Profil"].waitForExistence(timeout: timeout)
            || app.navigationBars.staticTexts["Profile"].waitForExistence(timeout: 4)
    }

    @discardableResult
    static func openSportProfileEditor(in app: XCUIApplication, timeout: TimeInterval = 15) -> Bool {
        tapTab(profileTab(in: app), in: app)
        XCTAssertTrue(waitForProfileTab(in: app))

        let favoriteTeam = app.staticTexts["AJ Auxerre"]
        let deadline = Date().addingTimeInterval(timeout)
        while Date() < deadline, !favoriteTeam.exists {
            RunLoop.current.run(until: Date().addingTimeInterval(0.25))
        }

        let editButton = sportProfileEditButton(in: app)
        scrollToElement(editButton, in: app, maxSwipes: 8)
        guard editButton.waitForExistence(timeout: 8) else { return false }
        tapElement(editButton)

        return app.navigationBars["Modifier le profile sportif"].waitForExistence(timeout: timeout)
    }

    static func waitForSportProfileJerseyField(
        in app: XCUIApplication,
        toContain value: String,
        timeout: TimeInterval = 12
    ) -> Bool {
        let jerseyField = app.textFields[UITestID.SportProfile.jerseyField]
        let deadline = Date().addingTimeInterval(timeout)
        while Date() < deadline {
            if jerseyField.waitForExistence(timeout: 1),
               (jerseyField.value as? String)?.contains(value) == true {
                return true
            }
            RunLoop.current.run(until: Date().addingTimeInterval(0.2))
        }
        return false
    }

    @discardableResult
    static func waitForProfileJersey(
        _ number: String,
        in app: XCUIApplication,
        timeout: TimeInterval = 12
    ) -> Bool {
        let predicate = NSPredicate(format: "label == %@ OR value == %@", number, number)
        return app.staticTexts.matching(predicate).firstMatch.waitForExistence(timeout: timeout)
    }

    static func tapSportProfileChip(_ label: String, in app: XCUIApplication) {
        let chip = app.buttons[label]
        scrollToElement(chip, in: app, maxSwipes: 12)
        XCTAssertTrue(chip.waitForExistence(timeout: 6))
        tapElement(chip)
    }

    static func profileSettingsButton(in app: XCUIApplication) -> XCUIElement {
        let byID = app.buttons[UITestID.Main.profileSettingsButton]
        if byID.exists { return byID }
        return app.buttons["Paramètres"]
    }

    static func profileLogoutButton(in app: XCUIApplication) -> XCUIElement {
        let byID = app.buttons[UITestID.Main.profileLogoutButton]
        if byID.exists { return byID }
        return app.buttons["Se déconnecter"]
    }

    static func waitForPresentation(
        of text: String,
        in app: XCUIApplication,
        timeout: TimeInterval = 8
    ) -> Bool {
        let candidates = [
            app.sheets.staticTexts[text],
            app.staticTexts[text],
            app.sheets.navigationBars.staticTexts[text],
            app.navigationBars.staticTexts[text],
        ]

        let deadline = Date().addingTimeInterval(timeout)
        while Date() < deadline {
            if candidates.contains(where: \.exists) {
                return true
            }
            RunLoop.current.run(until: Date().addingTimeInterval(0.2))
        }
        return false
    }

    static func dismissPresentation(in app: XCUIApplication) {
        let closeButtons = [
            app.sheets.buttons["Fermer"],
            app.buttons["Fermer"],
        ]
        if let button = closeButtons.first(where: \.exists) {
            button.tap()
            return
        }
        app.swipeDown()
    }

    static func notificationsButton(in app: XCUIApplication) -> XCUIElement {
        let byID = app.buttons[UITestID.Main.notificationsButton]
        if byID.exists { return byID }
        return app.navigationBars.buttons.matching(
            NSPredicate(format: "label CONTAINS[c] 'notification'")
        ).firstMatch
    }

    static func createMatchButton(in app: XCUIApplication) -> XCUIElement {
        let inNavigationBar = app.navigationBars.buttons[UITestID.Main.createMatchButton]
        if inNavigationBar.exists { return inNavigationBar }
        return app.buttons.matching(identifier: UITestID.Main.createMatchButton).firstMatch
    }

    static func fixtureMatchCard(in app: XCUIApplication) -> XCUIElement {
        app.buttons[UITestID.Match.listingCard(UITestID.Match.fixtureMatchId)]
    }

    static func finishedMatchCard(in app: XCUIApplication) -> XCUIElement {
        app.buttons[UITestID.Match.listingCard(UITestID.Match.finishedFixtureMatchId)]
    }

    @discardableResult
    static func openMatchDetail(
        matchId: String,
        in app: XCUIApplication,
        timeout: TimeInterval = 15
    ) -> Bool {
        guard waitForFixtureMatchList(in: app) else { return false }

        let card = app.buttons[UITestID.Match.listingCard(matchId)]
        let findDeadline = Date().addingTimeInterval(timeout)
        while Date() < findDeadline, !card.exists {
            app.swipeUp()
            RunLoop.current.run(until: Date().addingTimeInterval(0.2))
        }
        guard card.waitForExistence(timeout: 4) else { return false }

        scrollToElement(card, in: app, maxSwipes: 8)
        if card.isHittable {
            card.tap()
        } else {
            card.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).tap()
        }

        if matchId == UITestID.Match.finishedFixtureMatchId {
            return app.navigationBars.staticTexts["vs Champions FC"].waitForExistence(timeout: timeout)
                || app.staticTexts["Champions FC"].waitForExistence(timeout: 4)
        }

        if matchId == UITestID.Match.prepareFixtureMatchId {
            return app.navigationBars.staticTexts["vs Draft Opponent"].waitForExistence(timeout: timeout)
                || app.staticTexts["Draft Opponent"].waitForExistence(timeout: 4)
        }

        return app.navigationBars.staticTexts["vs Rival FC"].waitForExistence(timeout: timeout)
            || app.otherElements[UITestID.Match.detailView].waitForExistence(timeout: 4)
    }

    static func fillLoginAndSubmit(
        email: String = "uitest@levestaire.test",
        password: String = "Password1!",
        in app: XCUIApplication
    ) {
        let emailField = app.textFields[UITestID.Auth.emailField]
        let passwordField = app.secureTextFields[UITestID.Auth.passwordField]
        XCTAssertTrue(waitForExistence(of: emailField))
        emailField.clearAndTypeText(email)
        passwordField.clearAndTypeText(password)
        dismissKeyboard(in: app)
        app.buttons[UITestID.Auth.loginButton].tap()
    }

    static func registerPasswordField(_ id: String, in app: XCUIApplication) -> XCUIElement {
        let textField = app.textFields[id]
        if textField.exists { return textField }
        return app.secureTextFields[id]
    }

    static func fillRegisterFormAndAcceptLegal(
        in app: XCUIApplication,
        email: String = "alice@example.com",
        password: String = "password123"
    ) {
        app.textFields[UITestID.Register.lastNameField].clearAndTypeText("Martin")
        app.textFields[UITestID.Register.firstNameField].clearAndTypeText("Alice")
        app.textFields[UITestID.Register.emailField].clearAndTypeText(email)

        registerPasswordField(UITestID.Register.passwordField, in: app).clearAndTypeText(password)
        dismissKeyboard(in: app)

        registerPasswordField(UITestID.Register.confirmPasswordField, in: app).clearAndTypeText(password)
        dismissKeyboard(in: app)

        let legalToggle = app.switches[UITestID.Register.legalToggle]
        if legalToggle.waitForExistence(timeout: 2), legalToggle.value as? String == "0" {
            legalToggle.tap()
        }
    }

    @discardableResult
    static func applyMatchStatusFilter(_ statusLabel: String, in app: XCUIApplication) -> Bool {
        let filterButton = app.buttons[UITestID.Main.filterMatchesButton]
        XCTAssertTrue(filterButton.waitForExistence(timeout: 8))
        filterButton.tap()
        XCTAssertTrue(waitForPresentation(of: "Filtrer les matchs", in: app))

        let statusChip = app.buttons[statusLabel]
        XCTAssertTrue(statusChip.waitForExistence(timeout: 4))
        statusChip.tap()

        let applyButton = app.buttons["Appliquer"]
        XCTAssertTrue(applyButton.waitForExistence(timeout: 4))
        applyButton.tap()
        return true
    }

    static func openJoinTeamSheet(in app: XCUIApplication) {
        XCTAssertTrue(openTeamTab(in: app))
        let joinButton = app.buttons[UITestID.Main.joinTeamButton]
        XCTAssertTrue(joinButton.waitForExistence(timeout: 8))
        tapElement(joinButton)
        XCTAssertTrue(
            app.sheets.firstMatch.waitForExistence(timeout: 8)
                || app.navigationBars["Rejoindre une équipe"].waitForExistence(timeout: 4)
        )
    }

    static func openCreateTeamSheet(in app: XCUIApplication) {
        XCTAssertTrue(openTeamTab(in: app))
        let createButton = app.buttons[UITestID.Main.createTeamButton]
        XCTAssertTrue(createButton.waitForExistence(timeout: 8))
        tapElement(createButton)
        XCTAssertTrue(
            app.sheets.firstMatch.waitForExistence(timeout: 8)
                || app.staticTexts["Créer une nouvelle équipe"].waitForExistence(timeout: 4)
        )
    }

    static func tapMatchDetailTab(_ title: String, in app: XCUIApplication) {
        let picker = app.scrollViews[UITestID.Match.tabPicker]
        let tab = picker.buttons[title].exists ? picker.buttons[title] : app.buttons[title]
        var swipes = 0
        while swipes < 8, !tab.isHittable {
            if picker.exists {
                picker.swipeLeft()
            } else {
                app.swipeLeft()
            }
            swipes += 1
        }
        if !tab.isHittable {
            swipes = 0
            while swipes < 8, !tab.isHittable {
                if picker.exists {
                    picker.swipeRight()
                } else {
                    app.swipeRight()
                }
                swipes += 1
            }
        }
        XCTAssertTrue(tab.waitForExistence(timeout: 4), "Onglet \(title) introuvable")
        if tab.isHittable {
            tab.tap()
        } else {
            tab.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).tap()
        }
    }

    static func waitForFixtureMatchList(in app: XCUIApplication, timeout: TimeInterval = 12) -> Bool {
        fixtureMatchCard(in: app).waitForExistence(timeout: timeout)
    }

    @discardableResult
    static func waitForExistence(
        of element: XCUIElement,
        timeout: TimeInterval = 8
    ) -> Bool {
        element.waitForExistence(timeout: timeout)
    }

    static func dismissKeyboard(in app: XCUIApplication) {
        if app.toolbars.buttons["Terminé"].exists {
            app.toolbars.buttons["Terminé"].tap()
        } else if app.keyboards.element(boundBy: 0).exists {
            app.swipeDown()
        }
    }

    static func matchesTab(in app: XCUIApplication) -> XCUIElement {
        tabButton(in: app, identifiers: [UITestID.Tab.matches], labels: ["Matchs", "Matches"])
    }

    static func teamTab(in app: XCUIApplication) -> XCUIElement {
        tabButton(in: app, identifiers: [UITestID.Tab.team], labels: ["Équipe", "Team"])
    }

    static func teamSettingsButton(in app: XCUIApplication) -> XCUIElement {
        let byID = app.buttons[UITestID.Team.settingsButton]
        if byID.exists { return byID }
        return app.buttons["Paramètres"]
    }

    static func teamInvitePlayerButton(in app: XCUIApplication) -> XCUIElement {
        let byLabel = app.buttons.matching(
            NSPredicate(format: "label CONTAINS[c] 'Inviter un joueur'")
        ).firstMatch
        if byLabel.exists { return byLabel }
        return app.staticTexts["Inviter un joueur"]
    }

    @discardableResult
    static func openTeamTab(in app: XCUIApplication, timeout: TimeInterval = 0) -> Bool {
        let resolvedTimeout = timeout > 0 ? timeout : uiTestTimeout(default: 15, ci: 25)
        tapTab(teamTab(in: app), in: app)

        let teamNavTitle = app.navigationBars.staticTexts["Équipe"]
        let teamNavTitleEN = app.navigationBars.staticTexts["Team"]
        let hasNavTitle = teamNavTitle.waitForExistence(timeout: resolvedTimeout)
            || teamNavTitleEN.waitForExistence(timeout: 4)
        guard hasNavTitle else {
            return false
        }

        let deadline = Date().addingTimeInterval(resolvedTimeout)
        while Date() < deadline {
            if app.otherElements[UITestID.Team.shell].exists { return true }
            if app.staticTexts["FC Test UI"].exists { return true }
            RunLoop.current.run(until: Date().addingTimeInterval(0.25))
        }
        return false
    }

    private static func uiTestTimeout(default defaultTimeout: TimeInterval, ci: TimeInterval) -> TimeInterval {
        ProcessInfo.processInfo.environment["CI"] == "true" ? ci : defaultTimeout
    }

    static func profileTab(in app: XCUIApplication) -> XCUIElement {
        tabButton(in: app, identifiers: [UITestID.Tab.profile], labels: ["Profile", "Profil"])
    }

    private static func tabButton(
        in app: XCUIApplication,
        identifiers: [String],
        labels: [String]
    ) -> XCUIElement {
        for label in labels {
            let tabBarButton = app.tabBars.buttons[label]
            if tabBarButton.exists { return tabBarButton }
        }

        for identifier in identifiers {
            let tabBarButton = app.tabBars.buttons[identifier]
            if tabBarButton.exists { return tabBarButton }
        }

        for label in labels {
            if app.buttons[label].exists { return app.buttons[label] }
        }

        for identifier in identifiers {
            let predicate = NSPredicate(format: "identifier == %@", identifier)
            let match = app.descendants(matching: .any).matching(predicate).firstMatch
            if match.exists { return match }
        }

        return app.tabBars.buttons[labels[0]]
    }

    static func tapTab(_ element: XCUIElement, in app: XCUIApplication) {
        XCTAssertTrue(element.waitForExistence(timeout: 10), "Onglet introuvable")
        if element.isHittable {
            element.tap()
        } else {
            element.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).tap()
        }
    }

    static func scrollToElement(
        _ element: XCUIElement,
        in app: XCUIApplication,
        maxSwipes: Int = 6
    ) {
        var swipes = 0
        while !element.isHittable, swipes < maxSwipes {
            app.swipeUp()
            swipes += 1
        }
    }

    static func tapElement(_ element: XCUIElement) {
        if element.isHittable {
            element.tap()
        } else {
            element.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).tap()
        }
    }

    @discardableResult
    static func waitUntilEnabled(
        _ element: XCUIElement,
        timeout: TimeInterval = 15
    ) -> Bool {
        let deadline = Date().addingTimeInterval(timeout)
        while Date() < deadline {
            if element.exists, element.isEnabled {
                return true
            }
            RunLoop.current.run(until: Date().addingTimeInterval(0.2))
        }
        return element.exists && element.isEnabled
    }

    @discardableResult
    static func waitUntilSelected(
        _ element: XCUIElement,
        timeout: TimeInterval = 8
    ) -> Bool {
        let deadline = Date().addingTimeInterval(timeout)
        while Date() < deadline {
            if element.exists, element.isSelected {
                return true
            }
            RunLoop.current.run(until: Date().addingTimeInterval(0.2))
        }
        return element.exists && element.isSelected
    }

    static func fillMinimalSportProfile(in app: XCUIApplication) {
        let jerseyField = app.textFields[UITestID.SportProfile.jerseyField]
        scrollToElement(jerseyField, in: app)
        XCTAssertTrue(jerseyField.waitForExistence(timeout: 6))
        jerseyField.clearAndTypeText("10")
        if app.buttons["Terminé"].exists {
            app.buttons["Terminé"].tap()
        } else {
            dismissKeyboard(in: app)
        }

        let goalkeeper = app.buttons["Gardien"]
        scrollToElement(goalkeeper, in: app, maxSwipes: 12)
        XCTAssertTrue(goalkeeper.waitForExistence(timeout: 6))
        tapElement(goalkeeper)

        let monday = app.buttons["Lundi"]
        scrollToElement(monday, in: app, maxSwipes: 12)
        XCTAssertTrue(monday.waitForExistence(timeout: 6))
        tapElement(monday)
    }

    static func openCreateMatchSheet(in app: XCUIApplication) {
        let createMatch = createMatchButton(in: app)
        XCTAssertTrue(createMatch.waitForExistence(timeout: 10))
        tapElement(createMatch)
        XCTAssertTrue(waitForPresentation(of: "Nouveau match", in: app))
    }

    static func textField(
        matching label: String,
        in app: XCUIApplication
    ) -> XCUIElement {
        let candidates = [
            app.textFields[label],
            app.sheets.textFields[label],
        ]
        if let match = candidates.first(where: \.exists) {
            return match
        }

        let predicate = NSPredicate(
            format: "label CONTAINS[c] %@ OR placeholderValue CONTAINS[c] %@",
            label,
            label
        )
        let scoped = app.sheets.textFields.matching(predicate).firstMatch
        if scoped.exists { return scoped }
        return app.textFields.matching(predicate).firstMatch
    }

    @discardableResult
    static func waitForCreateMatchForm(
        in app: XCUIApplication,
        timeout: TimeInterval = 12
    ) -> Bool {
        let field = textField(matching: "adverse", in: app)
        let deadline = Date().addingTimeInterval(timeout)
        while Date() < deadline {
            if field.exists { return true }
            RunLoop.current.run(until: Date().addingTimeInterval(0.25))
        }
        return field.waitForExistence(timeout: 2)
    }

    static func fillCreateMatchForm(
        in app: XCUIApplication,
        opponent: String = "Test Opponent",
        location: String = "Stade Test"
    ) {
        XCTAssertTrue(waitForCreateMatchForm(in: app), "Le formulaire de création doit être chargé")

        let opponentField = textField(matching: "adverse", in: app)
        opponentField.clearAndTypeText(opponent)

        let locationField = textField(matching: "Lieu", in: app)
        scrollToElement(locationField, in: app)
        XCTAssertTrue(locationField.waitForExistence(timeout: 6))
        locationField.clearAndTypeText(location)
        dismissKeyboard(in: app)
    }

    static func createMatchSubmitButton(in app: XCUIApplication) -> XCUIElement {
        let sheetButton = app.sheets.buttons["Créer un match"]
        if sheetButton.exists { return sheetButton }
        return app.buttons.matching(
            NSPredicate(format: "identifier != %@ AND label == %@", UITestID.Main.createMatchButton, "Créer un match")
        ).firstMatch
    }

    @discardableResult
    static func confirmLogout(in app: XCUIApplication) -> Bool {
        let logoutButton = profileLogoutButton(in: app)
        scrollToElement(logoutButton, in: app, maxSwipes: 10)
        XCTAssertTrue(logoutButton.waitForExistence(timeout: 10))
        tapElement(logoutButton)

        let alert = app.alerts.firstMatch
        XCTAssertTrue(alert.waitForExistence(timeout: 4))

        let confirm = alert.buttons.matching(
            NSPredicate(format: "label != 'Annuler' AND label != 'Cancel'")
        ).firstMatch
        if confirm.exists {
            confirm.tap()
        } else {
            alert.buttons.element(boundBy: alert.buttons.count - 1).tap()
        }

        return app.textFields[UITestID.Auth.emailField].waitForExistence(timeout: 12)
            || app.textFields[UITestID.Auth.passwordField].waitForExistence(timeout: 4)
            || app.buttons[UITestID.Auth.loginButton].waitForExistence(timeout: 4)
    }
}

import XCTest

extension XCUIElement {
    func clearAndTypeText(_ text: String) {
        guard waitForExistence(timeout: 4) else { return }
        tap()

        let existingLength: Int
        if elementType == .secureTextField {
            // Les secure fields masquent la valeur : on efface large pour éviter les résidus.
            existingLength = 50
        } else if let stringValue = value as? String, !stringValue.isEmpty {
            existingLength = stringValue.count
        } else {
            existingLength = 0
        }

        if existingLength > 0 {
            let deleteString = String(repeating: XCUIKeyboardKey.delete.rawValue, count: existingLength)
            typeText(deleteString)
        }
        typeText(text)
    }
}
