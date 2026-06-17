//
//  L10n.swift
//  LeVestaire
//
//  Created by Corentin Robert on 17/06/2026.
//

import Foundation

enum L10n {
    private static var localization: LocalizationManager { LocalizationManager.shared }

    static func text(_ key: String.LocalizationValue) -> String {
        String(
            localized: key,
            bundle: localization.bundle,
            locale: localization.locale
        )
    }

    static func format(_ key: String.LocalizationValue, _ arguments: CVarArg...) -> String {
        let template = String(
            localized: key,
            bundle: localization.bundle,
            locale: localization.locale
        )
        return String(format: template, locale: localization.locale, arguments: arguments)
    }

    // MARK: - Navigation

    static var matches: String { text("matches") }
    static var team: String { text("team") }
    static var profile: String { text("profile") }
    static var notifications: String { text("notifications") }
    static var close: String { text("close") }
    static var noNotifications: String { text("noNotifications") }
    static var noNotificationsDescription: String { text("noNotificationsDescription") }

    // MARK: - Matchs

    static var newMatch: String { text("newMatch") }
    static var createMatch: String { text("createMatch") }
    static var filter: String { text("filter") }
    static var filterMatches: String { text("filterMatches") }
    static var period: String { text("period") }
    static var from: String { text("from") }
    static var to: String { text("to") }
    static var select: String { text("select") }
    static var reset: String { text("reset") }
    static var apply: String { text("apply") }
    static var filterStatusLabel: String { text("filterStatusLabel") }
    static var modify: String { text("modify") }
    static var retry: String { text("retry") }
    static var error: String { text("error") }
    static var loading: String { text("loading") }
    static var noMatchesFound: String { text("noMatchesFound") }
    static var createFirstMatchToStart: String { text("createFirstMatchToStart") }
    static var allMatchesLoaded: String { text("allMatchesLoaded") }
    static var scrollToLoadMore: String { text("scrollToLoadMore") }
    static var planMatchSubtitle: String { text("planMatchSubtitle") }
    static var activeFilters: String { text("activeFilters") }
    static var customPeriod: String { text("customPeriod") }
    static var matchesLoading: String { text("matchesLoading") }

    static func matchesLoadedCount(_ loaded: Int, total: Int) -> String {
        format("matchesLoadedCount", loaded, total)
    }

    static var scheduled: String { text("scheduled") }
    static var ongoing: String { text("ongoing") }
    static var finished: String { text("finished") }
    static var cancelled: String { text("cancelled") }
    static var postponed: String { text("postponed") }
    static var upcoming: String { text("upcoming") }
    static var scoreHidden: String { text("scoreHidden") }
    static var vs: String { text("vs") }
    static var opponentToBeDefined: String { text("opponentToBeDefined") }

    // MARK: - Match detail / create placeholders

    static var matchDetailTitle: String { text("matchDetailsTitle") }
    static var createMatchTitle: String { text("createMatchTitle") }
    static var createMatchPlaceholder: String { text("createMatchPlaceholder") }
    static var matchDetailPlaceholder: String { text("matchDetailPlaceholder") }

    // MARK: - Auth (Login / Register)

    static var login: String { text("login") }
    static var register: String { text("register") }
    static var ok: String { text("ok") }
    static var cancel: String { text("cancel") }
    static var validate: String { text("validate") }
    static var confirm: String { text("confirm") }
    static var continueButton: String { text("continueButton") }
    static var backToLogin: String { text("backToLogin") }

    static var loginHeroTitle: String { text("loginHeroTitle") }
    static var loginHeroSubtitle: String { text("loginHeroSubtitle") }
    static var registerHeroTitle: String { text("registerHeroTitle") }
    static var registerHeroSubtitle: String { text("registerHeroSubtitle") }

    static var email: String { text("email") }
    static var emailAddress: String { text("emailAddress") }
    static var password: String { text("password") }
    static var firstName: String { text("firstName") }
    static var lastName: String { text("lastName") }
    static var firstNameHint: String { text("firstNameHint") }
    static var lastNameHint: String { text("lastNameHint") }
    static var confirmPassword: String { text("confirmPassword") }
    static var birthdate: String { text("birthdate") }
    static var languageLabel: String { text("languageLabel") }
    static var preferredLanguage: String { text("preferredLanguage") }

    static var loginButton: String { text("loginButton") }
    static var loginInProgress: String { text("loginInProgress") }
    static var createAccount: String { text("createAccount") }
    static var createAccountButton: String { text("createAccountButton") }
    static var registerCreatingAccount: String { text("registerCreatingAccount") }
    static var noAccountYet: String { text("noAccountYet") }
    static var forgotPassword: String { text("forgotPassword") }
    static var forgotPasswordQuestion: String { text("forgotPasswordQuestion") }

    static var developerMode: String { text("developerMode") }
    static var enterDeveloperPassword: String { text("enterDeveloperPassword") }
    static var incorrectPassword: String { text("incorrectPassword") }
    static var accessRefused: String { text("accessRefused") }

    static var pleaseEnterYourEmail: String { text("pleaseEnterYourEmail") }
    static var passwordRequired: String { text("passwordRequired") }
    static var emailInvalid: String { text("emailInvalid") }
    static var passwordsDoNotMatch: String { text("passwordsDoNotMatch") }
    static var passwordMin8Characters: String { text("passwordMin8Characters") }
    static var verifyEmailBeforeLogin: String { text("verifyEmailBeforeLogin") }
    static var loginFailed: String { text("loginFailed") }
    static var registerFailed: String { text("registerFailed") }
    static var registerFormIncomplete: String { text("registerFormIncomplete") }
    static var invalidBirthDate: String { text("invalidBirthDate") }

    static var acceptLegalDocuments: String { text("acceptLegalDocuments") }
    static var legalConsentHint: String { text("legalConsentHint") }
    static var termsOfService: String { text("termsOfService") }
    static var betaDisclaimer: String { text("betaDisclaimer") }
    static var privacyPolicy: String { text("privacyPolicy") }

    static var french: String { text("french") }
    static var english: String { text("english") }

    // MARK: - Email verification

    static var emailVerificationNavTitle: String { text("emailVerificationNavTitle") }
    static var emailVerificationAlertTitle: String { text("emailVerificationAlertTitle") }
    static var emailVerificationChecking: String { text("emailVerificationChecking") }
    static var verificationEmailSentTo: String { text("verificationEmailSentTo") }
    static var clickLinkInEmail: String { text("clickLinkInEmail") }
    static var iHaveVerifiedMyEmail: String { text("iHaveVerifiedMyEmail") }
    static var resendEmail: String { text("resendEmail") }
    static var sendingInProgress: String { text("sendingInProgress") }
    static var checkSpamFolder: String { text("checkSpamFolder") }
    static var ensureEmailAddressCorrect: String { text("ensureEmailAddressCorrect") }
    static var waitFewMinutesBeforeResending: String { text("waitFewMinutesBeforeResending") }
    static var tipsTitle: String { text("tipsTitle") }

    static var emailNotYetVerified: String { text("emailNotYetVerified") }
    static var autoLoginFailedAfterVerification: String { text("autoLoginFailedAfterVerification") }
    static var autoLoginFailedManual: String { text("autoLoginFailedManual") }
    static var verificationEmailResent: String { text("verificationEmailResent") }
    static var verificationEmailResendFailed: String { text("verificationEmailResendFailed") }

    static func resendEmailCooldown(_ seconds: Int) -> String {
        format("resendEmailCooldown", seconds)
    }

    // MARK: - Forgot / reset password

    static var forgetPasswordDescription: String { text("forgetPasswordDescription") }
    static var forgetPasswordEmailHelper: String { text("forgetPasswordEmailHelper") }
    static var passwordResetEmailSentTitle: String { text("passwordResetEmailSentTitle") }
    static var passwordResetRequestFailed: String { text("passwordResetRequestFailed") }
    static var resetPasswordNavTitle: String { text("resetPasswordNavTitle") }
    static var resetPasswordInstructions: String { text("resetPasswordInstructions") }
    static var verificationCodeLabel: String { text("verificationCodeLabel") }
    static var verificationCodePlaceholder: String { text("verificationCodePlaceholder") }
    static var verificationCodeHelper: String { text("verificationCodeHelper") }
    static var confirmationLabel: String { text("confirmationLabel") }
    static var newPassword: String { text("newPassword") }
    static var resetPassword: String { text("resetPassword") }
    static var resetPasswordUpdating: String { text("resetPasswordUpdating") }
    static var resetPasswordSuccessAlertTitle: String { text("resetPasswordSuccessAlertTitle") }
    static var passwordUpdatedSuccessfully: String { text("passwordUpdatedSuccessfully") }
    static var fillAllFields: String { text("fillAllFields") }
    static var enterResetCode: String { text("enterResetCode") }
    static var resetPasswordFailed: String { text("resetPasswordFailed") }

    static func passwordResetEmailSentDefault(_ email: String) -> String {
        format("passwordResetEmailSentDefault", email)
    }

    // MARK: - Onboarding / Landing

    static var onboardingWelcomeTagline: String { text("onboardingWelcomeTagline") }
    static var onboardingTeamTitle: String { text("onboardingTeamTitle") }
    static var onboardingTeamSubtitle: String { text("onboardingTeamSubtitle") }
    static var onboardingPlanningTitle: String { text("onboardingPlanningTitle") }
    static var onboardingPlanningSubtitle: String { text("onboardingPlanningSubtitle") }
    static var onboardingStatsTitle: String { text("onboardingStatsTitle") }
    static var onboardingStatsSubtitle: String { text("onboardingStatsSubtitle") }
    static var next: String { text("next") }
    static var discover: String { text("discover") }

    // MARK: - Sport profile

    static var sportProfileTitle: String { text("sportProfileTitle") }
    static var completeYourProfile: String { text("completeYourProfile") }
    static var sportProfileSubtitle: String { text("sportProfileSubtitle") }
    static var sportInformationSection: String { text("sportInformationSection") }
    static var strongFoot: String { text("strongFoot") }
    static var jerseyNumberPlaceholder: String { text("jerseyNumberPlaceholder") }
    static var favoriteLeague: String { text("favoriteLeague") }
    static var favoriteTeam: String { text("favoriteTeam") }
    static var favoritePositionsSection: String { text("favoritePositionsSection") }
    static var experienceYearsSection: String { text("experienceYearsSection") }
    static var availabilitySection: String { text("availabilitySection") }
    static var profileEditableLater: String { text("profileEditableLater") }
    static var finalizeMyProfile: String { text("finalizeMyProfile") }
    static var saving: String { text("saving") }
    static var done: String { text("done") }
    static var completeRequiredSportFields: String { text("completeRequiredSportFields") }
    static var saveSportProfileFailed: String { text("saveSportProfileFailed") }
    static var uploadProfilePhotoFailed: String { text("uploadProfilePhotoFailed") }

    static var rightFoot: String { text("rightFoot") }
    static var leftFoot: String { text("leftFoot") }
    static var bothFeet: String { text("bothFeet") }

    static var goalkeeper: String { text("goalkeeper") }
    static var centerBack: String { text("centerBack") }
    static var rightBack: String { text("rightBack") }
    static var leftBack: String { text("leftBack") }
    static var defensiveMidfielder: String { text("defensiveMidfielder") }
    static var centerMidfielder: String { text("centerMidfielder") }
    static var attackingMidfielder: String { text("attackingMidfielder") }
    static var rightWinger: String { text("rightWinger") }
    static var leftWinger: String { text("leftWinger") }
    static var striker: String { text("striker") }
    static var secondStriker: String { text("secondStriker") }

    static var footballLevelBeginner: String { text("football_level_beginner") }
    static var footballLevelIntermediate: String { text("football_level_intermediate") }
    static var footballLevelAdvanced: String { text("football_level_advanced") }
    static var footballLevelExpert: String { text("football_level_expert") }

    static var monday: String { text("monday") }
    static var tuesday: String { text("tuesday") }
    static var wednesday: String { text("wednesday") }
    static var thursday: String { text("thursday") }
    static var friday: String { text("friday") }
    static var saturday: String { text("saturday") }
    static var sunday: String { text("sunday") }

    // MARK: - Profile / Team tabs

    static var profileSettingsDescription: String { text("profileSettingsDescription") }
    static var settings: String { text("settings") }
    static var appLanguage: String { text("appLanguage") }
    static var editSportifProfile: String { text("editSportifProfile") }
    static var statistics: String { text("statistics") }
    static var seasonStats: String { text("seasonStats") }
    static var userStatsSubtitle: String { text("userStatsSubtitle") }
    static var noStatisticsAvailable: String { text("noStatisticsAvailable") }
    static var season: String { text("season") }
    static var jerseyNumber: String { text("jerseyNumber") }
    static var save: String { text("save") }
    static var none: String { text("none") }
    static var confirmLogout: String { text("confirmLogout") }
    static var deleteAccount: String { text("deleteAccount") }
    static var deleteAccountConfirmTitle: String { text("deleteAccountConfirmTitle") }
    static var deleteAccountConfirmMessage: String { text("deleteAccountConfirmMessage") }
    static var deleteAccountSuccess: String { text("deleteAccountSuccess") }
    static var deleteAccountError: String { text("deleteAccountError") }
    static var accountDeletionInProgress: String { text("accountDeletionInProgress") }
    static var cancelDeletion: String { text("cancelDeletion") }
    static var accountDeletionCancelled: String { text("accountDeletionCancelled") }
    static var cancelDeletionError: String { text("cancelDeletionError") }
    static var biometricLogin: String { text("biometricLogin") }
    static var biometricLoginDescription: String { text("biometricLoginDescription") }
    static var biometricUnavailable: String { text("biometricUnavailable") }
    static var biometricEnableReason: String { text("biometricEnableReason") }
    static var biometricAuthenticationFailed: String { text("biometricAuthenticationFailed") }
    static var biometricNotEnrolled: String { text("biometricNotEnrolled") }
    static var biometricLockout: String { text("biometricLockout") }
    static var biometricCancelled: String { text("biometricCancelled") }

    static func accountDeletionScheduled(_ days: Int) -> String {
        format("accountDeletionScheduled", days)
    }

    static var matchesPlayed: String { text("matchesPlayed") }
    static var minutesPlayed: String { text("minutesPlayed") }
    static var goals: String { text("goals") }
    static var assists: String { text("assists") }
    static var ownGoals: String { text("ownGoals") }
    static var yellowCards: String { text("yellowCards") }
    static var redCards: String { text("redCards") }
    static var shotsOnTarget: String { text("shotsOnTarget") }
    static var saves: String { text("saves") }
    static var substitutionsIn: String { text("substitutionsIn") }
    static var substitutionsOut: String { text("substitutionsOut") }

    static var logout: String { text("logout") }
    static var logoutInProgress: String { text("logoutInProgress") }
    static var signOutButton: String { text("signOutButton") }
    static var teamTabDescription: String { text("teamTabDescription") }

    // MARK: - Profile photo

    static var choosePhoto: String { text("choosePhoto") }
    static var profilePhoto: String { text("profilePhoto") }
    static var photoLibrary: String { text("photoLibrary") }
    static var camera: String { text("camera") }
    static var deletePhoto: String { text("deletePhoto") }

    // MARK: - Legal documents

    static var loadingDocument: String { text("loadingDocument") }
    static var documentLoadFailed: String { text("documentLoadFailed") }
    static var documentUnreadable: String { text("documentUnreadable") }

    // MARK: - Developer

    static var developerViewTitle: String { text("developerViewTitle") }
    static var informationTitle: String { text("informationTitle") }
    static var apiEnvironment: String { text("apiEnvironment") }
    static var environment: String { text("environment") }
    static var versionLabel: String { text("versionLabel") }
    static var buildNumberLabel: String { text("buildNumberLabel") }
    static var platformLabel: String { text("platformLabel") }
    static var testedUrlLabel: String { text("testedUrlLabel") }
    static var testUrlInProgress: String { text("testUrlInProgress") }
    static var testUrlButton: String { text("testUrlButton") }
    static var connectingToApi: String { text("connectingToApi") }
    static var productionEnvironment: String { text("productionEnvironment") }
    static var developmentEnvironment: String { text("developmentEnvironment") }
    static var customUrl: String { text("customUrl") }
    static var apiEnvironmentDev: String { text("apiEnvironmentDev") }

    static func serverReachable(statusCode: Int, durationMs: Int) -> String {
        format("serverReachable", statusCode, durationMs)
    }

    // MARK: - Errors / Network

    static var sessionRequired: String { text("sessionRequired") }
    static var invalidApiBaseUrl: String { text("invalidApiBaseUrl") }
    static var invalidServerResponse: String { text("invalidServerResponse") }
    static var invalidApiResponse: String { text("invalidApiResponse") }
    static var invalidApiResponseNoData: String { text("invalidApiResponseNoData") }
    static var invalidProfilePictureApiResponse: String { text("invalidProfilePictureApiResponse") }
    static var prepareProfilePhotoFailed: String { text("prepareProfilePhotoFailed") }
    static var apiUrlEmpty: String { text("apiUrlEmpty") }
    static var apiUrlInvalid: String { text("apiUrlInvalid") }
    static var invalidDateOrMissing: String { text("invalidDateOrMissing") }
    static var defaultMatchTitle: String { text("defaultMatchTitle") }
    static var deletedUser: String { text("deletedUser") }
    static var customApiUrlPlaceholder: String { text("customApiUrlPlaceholder") }

    static var ligue1Label: String { text("ligue1Label") }
    static var premierLeagueLabel: String { text("premierLeagueLabel") }
    static var bundesligaLabel: String { text("bundesligaLabel") }
    static var serieALabel: String { text("serieALabel") }
    static var laLigaLabel: String { text("laLigaLabel") }

    static func loginErrorWithDetail(_ detail: String) -> String {
        format("loginErrorWithDetail", detail)
    }

    static func registerErrorWithDetail(_ detail: String) -> String {
        format("registerErrorWithDetail", detail)
    }

    static func resendVerificationErrorWithDetail(_ detail: String) -> String {
        format("resendVerificationErrorWithDetail", detail)
    }

    static func emailVerificationErrorWithDetail(_ detail: String) -> String {
        format("emailVerificationErrorWithDetail", detail)
    }

    static func passwordResetRequestErrorWithDetail(_ detail: String) -> String {
        format("passwordResetRequestErrorWithDetail", detail)
    }

    static func passwordResetConfirmErrorWithDetail(_ detail: String) -> String {
        format("passwordResetConfirmErrorWithDetail", detail)
    }

    static func saveSportProfileErrorWithDetail(_ detail: String) -> String {
        format("saveSportProfileErrorWithDetail", detail)
    }

    static func uploadPhotoErrorWithDetail(_ detail: String) -> String {
        format("uploadPhotoErrorWithDetail", detail)
    }

    static func loadMatchesFailedWithCode(_ code: Int) -> String {
        format("loadMatchesFailedWithCode", code)
    }

    static func decodeApiResponseFailed(_ typeName: String) -> String {
        format("decodeApiResponseFailed", typeName)
    }

    static func versionWithNumber(_ version: String) -> String {
        format("versionWithNumber", version)
    }

    static var oneDayAgo: String { text("oneDayAgo") }
    static var oneHourAgo: String { text("oneHourAgo") }
    static var oneMinuteAgo: String { text("oneMinuteAgo") }

    static func daysAgo(_ count: Int) -> String {
        format("daysAgo", count)
    }

    static func hoursAgo(_ count: Int) -> String {
        format("hoursAgo", count)
    }

    static func minutesAgo(_ count: Int) -> String {
        format("minutesAgo", count)
    }

    static func apiMessage(_ code: String?) -> String? {
        APIErrorLocalizer.localized(code)
    }

    static func apiErrorMessage(message: String?, error: String?, fallback: String) -> String {
        APIErrorLocalizer.message(message: message, error: error, fallback: fallback)
    }
}
