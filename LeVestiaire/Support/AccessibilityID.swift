//
//  AccessibilityID.swift
//  LeVestaire
//

import Foundation

enum AccessibilityID {
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
        static let fixtureMatchId = UITestFixtureResponses.matchId
        static let finishedFixtureMatchId = UITestFixtureResponses.finishedMatchId
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
