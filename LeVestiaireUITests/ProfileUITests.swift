//
//  ProfileUITests.swift
//  LeVestiaireUITests
//

import XCTest

final class ProfileUITests: XCTestCase {
    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    @MainActor
    func testProfile_displaysSportProfileSummary() throws {
        let app = UITestApp.launch(scenario: .authenticated)
        UITestApp.tapTab(UITestApp.profileTab(in: app), in: app)
        XCTAssertTrue(UITestApp.waitForProfileTab(in: app))

        XCTAssertTrue(app.staticTexts["AJ Auxerre"].waitForExistence(timeout: 12))
        XCTAssertTrue(app.staticTexts["Pied droit"].exists)
        XCTAssertTrue(app.staticTexts["10"].exists)
    }

    @MainActor
    func testProfile_editSportProfile_loadsExistingDataAndSaves() throws {
        let app = UITestApp.launch(scenario: .authenticated)

        XCTAssertTrue(
            UITestApp.openSportProfileEditor(in: app),
            "L'éditeur de profil sportif doit s'ouvrir depuis l'onglet Profil"
        )
        XCTAssertTrue(
            UITestApp.waitForSportProfileJerseyField(in: app, toContain: "10"),
            "Le profil existant doit être chargé avant modification"
        )
        XCTAssertTrue(
            UITestApp.waitUntilSelected(app.buttons["Lundi"]),
            "Le profil existant doit préremplir les disponibilités"
        )

        UITestApp.tapSportProfileChip("Mardi", in: app)
        XCTAssertTrue(
            UITestApp.waitUntilSelected(app.buttons["Mardi"]),
            "Le jour ajouté doit être sélectionné avant l'enregistrement"
        )

        let save = UITestApp.sportProfileSubmitButton(in: app)
        UITestApp.scrollToElement(save, in: app, maxSwipes: 12)
        XCTAssertTrue(save.waitForExistence(timeout: 6))
        XCTAssertTrue(
            UITestApp.waitUntilEnabled(save),
            "Le bouton d'enregistrement doit être actif en mode édition"
        )
        UITestApp.tapElement(save)

        XCTAssertTrue(
            UITestApp.waitForProfileTab(in: app, timeout: 12),
            "L'enregistrement doit revenir à l'onglet Profil"
        )
        XCTAssertFalse(
            app.navigationBars["Modifier le profile sportif"].exists,
            "L'écran d'édition doit être fermé après enregistrement"
        )
    }
}
