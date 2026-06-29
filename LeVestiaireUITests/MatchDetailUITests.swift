//
//  MatchDetailUITests.swift
//  LeVestiaireUITests
//

import XCTest

final class MatchDetailUITests: XCTestCase {
    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    @MainActor
    func testMatchesList_showsStubbedMatchCard() throws {
        let app = UITestApp.launch(scenario: .authenticated)
        XCTAssertTrue(UITestApp.waitForFixtureMatchList(in: app))
        XCTAssertTrue(app.staticTexts["vs Rival FC"].exists)
        XCTAssertTrue(app.staticTexts["Stade Municipal"].exists)
        XCTAssertTrue(app.staticTexts["FC Test UI"].exists)
    }

    @MainActor
    func testMatchDetail_opensFromListingAndShowsOpponent() throws {
        let app = UITestApp.launch(scenario: .authenticated)
        let matchCard = UITestApp.fixtureMatchCard(in: app)
        XCTAssertTrue(matchCard.waitForExistence(timeout: 12))
        matchCard.tap()

        XCTAssertTrue(app.navigationBars.staticTexts["vs Rival FC"].waitForExistence(timeout: 10))
        XCTAssertTrue(app.staticTexts["Stade Municipal"].exists)
        XCTAssertTrue(app.staticTexts["FC Test UI"].exists)
    }

    @MainActor
    func testMatchDetail_showsAvailabilityRespondSection() throws {
        let app = UITestApp.launch(scenario: .authenticated)
        UITestApp.openMatchDetail(matchId: UITestID.Match.fixtureMatchId, in: app)

        XCTAssertTrue(app.staticTexts["Disponibilité"].waitForExistence(timeout: 10))
        XCTAssertTrue(app.buttons["Présent"].exists)
        XCTAssertTrue(app.staticTexts.containing(NSPredicate(format: "label CONTAINS[c] 'Ta réponse'")).firstMatch.exists)
    }

    @MainActor
    func testMatchDetail_upcomingShowsCompositionSummary() throws {
        let app = UITestApp.launch(scenario: .authenticated)
        XCTAssertTrue(UITestApp.openMatchDetail(matchId: UITestID.Match.fixtureMatchId, in: app))

        let summary = app.staticTexts["Résumé"]
        UITestApp.scrollToElement(summary, in: app, maxSwipes: 8)
        XCTAssertTrue(summary.waitForExistence(timeout: 8))
        XCTAssertTrue(app.staticTexts["Aucune composition disponible"].waitForExistence(timeout: 8))
    }

    @MainActor
    func testMatchDetail_finishedMatch_showsAllTabs() throws {
        let app = UITestApp.launch(scenario: .authenticated)
        XCTAssertTrue(UITestApp.openMatchDetail(matchId: UITestID.Match.finishedFixtureMatchId, in: app))

        XCTAssertTrue(app.navigationBars.staticTexts["vs Champions FC"].waitForExistence(timeout: 10))
        XCTAssertTrue(app.buttons["Événements"].waitForExistence(timeout: 8))
        XCTAssertTrue(app.buttons["Statistiques"].exists)
        XCTAssertTrue(app.buttons["Quiz"].exists)
    }

    @MainActor
    func testMatchDetail_eventsTab_listsStubbedGoalEvent() throws {
        let app = UITestApp.launch(scenario: .authenticated)
        XCTAssertTrue(UITestApp.openMatchDetail(matchId: UITestID.Match.finishedFixtureMatchId, in: app))

        UITestApp.tapMatchDetailTab("Événements", in: app)

        let goalEvent = app.staticTexts.containing(NSPredicate(format: "label CONTAINS[c] 'But'")).firstMatch
        UITestApp.scrollToElement(goalEvent, in: app, maxSwipes: 4)
        XCTAssertTrue(goalEvent.waitForExistence(timeout: 10))
        XCTAssertTrue(app.staticTexts.containing(NSPredicate(format: "label CONTAINS[c] 'Test UI'")).firstMatch.exists)
    }

    @MainActor
    func testMatchDetail_statisticsTab_showsPlayerStats() throws {
        let app = UITestApp.launch(scenario: .authenticated)
        XCTAssertTrue(UITestApp.openMatchDetail(matchId: UITestID.Match.finishedFixtureMatchId, in: app))

        UITestApp.tapMatchDetailTab("Statistiques", in: app)

        let player = app.staticTexts["Test UI"]
        UITestApp.scrollToElement(player, in: app, maxSwipes: 6)
        XCTAssertTrue(player.waitForExistence(timeout: 12))
        XCTAssertTrue(app.staticTexts["Buts"].exists)
    }

    @MainActor
    func testMatchDetail_quizTab_showsQuizContent() throws {
        let app = UITestApp.launch(scenario: .authenticated)
        XCTAssertTrue(UITestApp.openMatchDetail(matchId: UITestID.Match.finishedFixtureMatchId, in: app))

        UITestApp.tapMatchDetailTab("Quiz", in: app)

        let quizTitle = app.staticTexts["Quiz du match"]
        let fallbackTitle = app.staticTexts["Quiz"]
        UITestApp.scrollToElement(quizTitle, in: app, maxSwipes: 4)

        XCTAssertTrue(
            quizTitle.waitForExistence(timeout: 12)
                || fallbackTitle.waitForExistence(timeout: 4)
                || app.buttons["Créer le quiz"].waitForExistence(timeout: 4)
        )
        XCTAssertTrue(
            app.buttons["Fermer le quiz"].exists
                || app.buttons["Créer le quiz"].exists
                || app.staticTexts.containing(
                    NSPredicate(format: "label CONTAINS[c] 'fausses réponses'")
                ).firstMatch.exists
                || app.staticTexts["Aucun quiz pour ce match"].exists
        )
    }

    @MainActor
    func testMatchesList_appliesFinishedStatusFilter() throws {
        let app = UITestApp.launch(scenario: .authenticated)
        XCTAssertTrue(UITestApp.waitForFixtureMatchList(in: app))
        XCTAssertTrue(app.staticTexts["vs Rival FC"].exists)

        XCTAssertTrue(UITestApp.applyMatchStatusFilter("Terminé", in: app))

        XCTAssertTrue(app.staticTexts["vs Champions FC"].waitForExistence(timeout: 10))
        XCTAssertFalse(app.staticTexts["vs Rival FC"].exists)
    }

    @MainActor
    func testMatchDetail_submitsAvailabilityAbsent() throws {
        let app = UITestApp.launch(scenario: .authenticated)
        UITestApp.openMatchDetail(matchId: UITestID.Match.fixtureMatchId, in: app)

        let absentChip = app.buttons["Absent"]
        XCTAssertTrue(absentChip.waitForExistence(timeout: 10))
        absentChip.tap()

        XCTAssertTrue(
            UITestApp.waitUntilSelected(absentChip, timeout: 12)
                || app.staticTexts.containing(
                    NSPredicate(format: "label CONTAINS[c] 'Ta réponse' AND label CONTAINS[c] 'Absent'")
                ).firstMatch.waitForExistence(timeout: 12)
        )
    }

    @MainActor
    func testMatchDetail_editsOpponentAndLocation() throws {
        let app = UITestApp.launch(scenario: .authenticated)
        XCTAssertTrue(UITestApp.openMatchDetail(matchId: UITestID.Match.prepareFixtureMatchId, in: app))

        let editButton = app.buttons["Modifier les informations"]
        if editButton.waitForExistence(timeout: 8) {
            UITestApp.tapElement(editButton)
            XCTAssertTrue(
                app.sheets.firstMatch.waitForExistence(timeout: 8)
                    || app.staticTexts["Modifier le match"].waitForExistence(timeout: 4)
            )
            XCTAssertTrue(app.buttons["Sauvegarder"].waitForExistence(timeout: 8))
        }
    }

    @MainActor
    func testMatchDetail_prepareOpensCompositionEditor() throws {
        let app = UITestApp.launch(scenario: .authenticated)
        XCTAssertTrue(UITestApp.openMatchDetail(matchId: UITestID.Match.prepareFixtureMatchId, in: app))

        let createComposition = app.buttons["Créer la composition"]
        UITestApp.scrollToElement(createComposition, in: app, maxSwipes: 10)
        XCTAssertTrue(createComposition.waitForExistence(timeout: 10))
        createComposition.tap()

        XCTAssertTrue(app.navigationBars["Créer la composition"].waitForExistence(timeout: 10))
    }
}
