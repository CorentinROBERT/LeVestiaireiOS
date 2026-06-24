//
//  APIEndpoints.swift
//  LeVestaire
//
//  Created by Corentin Robert on 15/06/2026.
//

import Foundation

enum APIEndpoints {
    // MARK: - Auth

    static let login = "/api/v1/auth/login"
    static let register = "/api/v1/auth/register"
    static let refresh = "/api/v1/auth/refresh-token"
    static let verify = "/api/v1/auth/verify"
    static let resendVerification = "/api/v1/auth/resend-verification"
    static let checkVerification = "/api/v1/auth/check-verification"
    static let logout = "/api/v1/auth/logout"
    static let me = "/api/v1/me"

    // MARK: - Mot de passe oublié

    static let requestPasswordReset = "/api/v1/auth/request-password-reset"
    static let confirmPasswordReset = "/api/v1/auth/confirm-password-reset"

    // MARK: - Users

    static let users = "/api/v1/users"
    static let userById = "/api/v1/users/{id}"

    // MARK: - Account Deletion

    static let accountDeletionRequest = "/api/v1/users/account/deletion/request"
    static let accountDeletionCancel = "/api/v1/users/account/deletion/cancel"

    // MARK: - Teams

    static let teams = "/api/v1/teams"
    static let teamById = "/api/v1/teams/{id}"
    static let teamsMe = "/api/v1/teams/me"
    static let userTeams = teamsMe

    static func updateTeam(_ teamId: String) -> String {
        "/api/v1/teams/\(teamId)"
    }

    static func updateMemberRole(teamId: String, memberId: String) -> String {
        "/api/v1/teams/\(teamId)/members/\(memberId)/role"
    }

    static func removeMember(teamId: String, memberId: String) -> String {
        "/api/v1/teams/\(teamId)/members/\(memberId)"
    }

    static func leaveTeam(_ teamId: String) -> String {
        "/api/v1/teams/\(teamId)/leave"
    }

    // MARK: - Guests (Invités)

    static func teamGuests(_ teamId: String) -> String {
        "/api/v1/teams/\(teamId)/guests"
    }

    static func createTeamGuest(_ teamId: String) -> String {
        "/api/v1/teams/\(teamId)/guests"
    }

    static func guestById(_ guestId: String) -> String {
        "/api/v1/guests/\(guestId)"
    }

    static func mergeGuest(_ guestId: String) -> String {
        "/api/v1/guests/\(guestId)/merge"
    }

    // MARK: - Team Invitations

    static func teamInvite(_ teamId: String) -> String {
        "/api/v1/teams/\(teamId)/invite"
    }

    static func teamInviteRegenerate(_ teamId: String) -> String {
        "/api/v1/teams/\(teamId)/invite/regenerate"
    }

    static func teamInviteByCode(_ code: String) -> String {
        "/api/v1/teams/invite/\(code)"
    }

    static let teamsJoin = "/api/v1/teams/join"

    static func teamInvitations(_ teamId: String) -> String {
        "/api/v1/teams/\(teamId)/invitations"
    }

    static func acceptInvitation(_ invitationId: String) -> String {
        "/api/v1/invitations/\(invitationId)/accept"
    }

    static func declineInvitation(_ invitationId: String) -> String {
        "/api/v1/invitations/\(invitationId)/decline"
    }

    static func cancelInvitation(_ invitationId: String) -> String {
        "/api/v1/invitations/\(invitationId)"
    }

    static func resendInvitation(_ invitationId: String) -> String {
        "/api/v1/invitations/\(invitationId)/resend"
    }

    static func userInvitations(_ userId: String) -> String {
        "/api/v1/users/\(userId)/invitations"
    }

    // MARK: - Players

    static let players = "/api/v1/players"
    static let playerById = "/api/v1/players/{id}"

    // MARK: - Matches

    static let matches = "/api/v1/matches"
    static let availableSeasons = "/api/v1/matches/seasons/available"

    static func createMatch() -> String {
        "/api/v1/matches"
    }

    static func getMatch(_ matchId: String) -> String {
        "/api/v1/matches/\(matchId)"
    }

    static func updateMatch(_ matchId: String) -> String {
        "/api/v1/matches/\(matchId)"
    }

    static func updateMatchScore(_ matchId: String) -> String {
        "/api/v1/matches/\(matchId)/score"
    }

    static func updateMatchStatus(_ matchId: String) -> String {
        "/api/v1/matches/\(matchId)/status"
    }

    static func deleteMatch(_ matchId: String) -> String {
        "/api/v1/matches/\(matchId)"
    }

    // MARK: - Match Events

    static func matchEvents(_ matchId: String) -> String {
        "/api/v1/matches/\(matchId)/events"
    }

    static func matchEventById(matchId: String, eventId: String) -> String {
        "/api/v1/matches/\(matchId)/events/\(eventId)"
    }

    // MARK: - Match Availability

    static func matchAvailability(_ matchId: String) -> String {
        "/api/v1/matches/\(matchId)/availability"
    }

    static func matchAvailabilityRoster(_ matchId: String) -> String {
        "/api/v1/matches/\(matchId)/availability/roster"
    }

    static func matchAvailabilityMe(_ matchId: String) -> String {
        "/api/v1/matches/\(matchId)/availability/me"
    }

    static func matchSelectablePlayers(_ matchId: String) -> String {
        "/api/v1/matches/\(matchId)/selectable-players"
    }

    static func matchLockComposition(_ matchId: String) -> String {
        "/api/v1/matches/\(matchId)/composition/lock"
    }

    static func matchComposition(_ matchId: String) -> String {
        "/api/v1/matches/\(matchId)/composition"
    }

    static func matchAvailabilityPlayer(_ matchId: String, playerId: String) -> String {
        "/api/v1/matches/\(matchId)/availability/\(playerId)"
    }

    // MARK: - Compositions

    static let compositions = "/api/v1/compositions"
    static let compositionById = "/api/v1/compositions/{id}"
    static let compositionValidate = "/api/v1/compositions/{id}/validate"

    static func createComposition() -> String {
        "/api/v1/compositions"
    }

    static func getComposition(_ id: String) -> String {
        "/api/v1/compositions/\(id)"
    }

    static func updateComposition(_ id: String) -> String {
        "/api/v1/compositions/\(id)"
    }

    static func deleteComposition(_ id: String) -> String {
        "/api/v1/compositions/\(id)"
    }

    static func teamCompositions(_ teamId: String) -> String {
        "/api/v1/compositions/team/\(teamId)"
    }

    static func teamCompositionMembers(_ teamId: String) -> String {
        "/api/v1/compositions/team/\(teamId)/members"
    }

    static func addAlternativeFormation(_ compositionId: String) -> String {
        "/api/v1/compositions/\(compositionId)/alternatives"
    }

    static func updateAlternativeFormation(compositionId: String, altId: String) -> String {
        "/api/v1/compositions/\(compositionId)/alternatives/\(altId)"
    }

    static func deleteAlternativeFormation(compositionId: String, altId: String) -> String {
        "/api/v1/compositions/\(compositionId)/alternatives/\(altId)"
    }

    // MARK: - Health

    static let health = "/api/health"

    // MARK: - Device Tokens (Push Notifications)

    static let deviceTokens = "/api/v1/device-tokens"
    static let testPushNotification = "/api/v1/notifications/test-push"

    // MARK: - In-App Notifications

    static let notifications = "/api/v1/notifications"
    static let notificationsUnreadCount = "/api/v1/notifications/unread-count"
    static let notificationsReadAll = "/api/v1/notifications/read-all"

    static func notificationRead(_ id: String) -> String {
        "/api/v1/notifications/\(id)/read"
    }

    static func notificationArchive(_ id: String) -> String {
        "/api/v1/notifications/\(id)/archive"
    }

    static func notificationUnarchive(_ id: String) -> String {
        "/api/v1/notifications/\(id)/unarchive"
    }

    // MARK: - Sport Profile

    static let sportProfile = "/api/v1/sport-profile"

    // MARK: - Profile Picture

    static let profilePicture = "/api/v1/users/profile-picture"

    // MARK: - Reference Data

    static let leagues = "/api/v1/reference-data/leagues"

    static func teamsForLeague(_ leagueKey: String) -> String {
        "/api/v1/reference-data/leagues/\(leagueKey)/teams"
    }

    // MARK: - Stats

    static func matchStats(_ matchId: String) -> String {
        "/api/v1/matches/\(matchId)/stats"
    }

    static func teamSeasonStats(teamId: String, season: String) -> String {
        "/api/v1/teams/\(teamId)/seasons/\(season)/stats"
    }

    static func userSeasonStats(userId: String, season: String) -> String {
        "/api/v1/users/\(userId)/seasons/\(season)/stats"
    }

    static func teamSeasonRankings(teamId: String, season: String) -> String {
        "/api/v1/teams/\(teamId)/seasons/\(season)/rankings"
    }

    // MARK: - Quizzes

    static func quizzesForMatch(_ matchId: String, lang: String? = nil) -> String {
        let url = "/api/v1/quizzes/matches/\(matchId)"
        guard let lang else { return url }
        return "\(url)?lang=\(lang)"
    }

    static func quizById(_ quizId: String, lang: String? = nil) -> String {
        let url = "/api/v1/quizzes/\(quizId)"
        guard let lang else { return url }
        return "\(url)?lang=\(lang)"
    }

    static func createQuiz(_ matchId: String) -> String {
        "/api/v1/quizzes/matches/\(matchId)"
    }

    static func quizPatch(_ quizId: String) -> String {
        "/api/v1/quizzes/\(quizId)"
    }

    static func quizSubmit(_ quizId: String) -> String {
        "/api/v1/quizzes/\(quizId)/submit"
    }

    static func quizResults(_ quizId: String) -> String {
        "/api/v1/quizzes/\(quizId)/results"
    }

    static func quizLeaderboard(_ quizId: String) -> String {
        "/api/v1/quizzes/\(quizId)/leaderboard"
    }

    static func quizUserSubmission(_ quizId: String) -> String {
        "/api/v1/quizzes/\(quizId)/user-submission"
    }

    static func deleteQuiz(_ quizId: String) -> String {
        "/api/v1/quizzes/\(quizId)"
    }

    // MARK: - Helpers

    static func buildURL(_ endpoint: String, pathParams: [String: String]? = nil) -> String {
        guard let pathParams else { return endpoint }

        var url = endpoint
        for (key, value) in pathParams {
            url = url.replacingOccurrences(of: "{\(key)}", with: value)
        }
        return url
    }
}
