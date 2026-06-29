//
//  UITestFixtureResponses.swift
//  LeVestaire
//

import Foundation

enum UITestFixtureResponses {
    static let matchId = "ui-test-match-1"
    static let finishedMatchId = "ui-test-match-finished"
    static let createdMatchId = "ui-test-match-created"
    static let prepareMatchId = "ui-test-match-prepare"
    static let teamId = "ui-test-team-1"
    static let searchableTeamId = "ui-test-search-team"
    static let createdTeamId = "ui-test-team-created"
    static let quizId = "ui-test-quiz-1"

    struct FixtureResponse {
        let statusCode: Int
        let data: Data
    }

    static func response(for request: URLRequest) -> FixtureResponse {
        let path = request.url?.path ?? ""
        let method = request.httpMethod ?? "GET"

        if method == "POST", path.hasSuffix("/auth/login") {
            return FixtureResponse(statusCode: 200, data: loginJSON)
        }

        if method == "POST", path.contains("/auth/register") {
            return FixtureResponse(statusCode: 200, data: registerJSON)
        }

        if method == "POST", path.hasSuffix("/auth/request-password-reset") {
            return FixtureResponse(statusCode: 200, data: passwordResetJSON)
        }

        if method == "PATCH", path.contains("/matches/") {
            applyMatchPatch(from: request, path: path)
            if let id = matchId(from: path) {
                if id == prepareMatchId {
                    return FixtureResponse(statusCode: 200, data: prepareMatchDetailJSON())
                }
                return FixtureResponse(statusCode: 200, data: matchDetailJSON(for: id))
            }
        }

        if method == "PUT", path.contains("/availability/me") {
            applyMyAvailability(from: request, path: path)
            let matchId = matchId(from: path) ?? Self.matchId
            return FixtureResponse(statusCode: 200, data: myAvailabilityResponseJSON(for: matchId))
        }

        if method == "GET", path.hasSuffix("/matches/\(finishedMatchId)") {
            return FixtureResponse(statusCode: 200, data: finishedMatchDetailJSON)
        }

        if method == "GET", path.hasSuffix("/matches/\(createdMatchId)") {
            return FixtureResponse(statusCode: 200, data: createdMatchDetailJSON)
        }

        if method == "GET", path.hasSuffix("/matches/\(prepareMatchId)") {
            return FixtureResponse(statusCode: 200, data: prepareMatchDetailJSON())
        }

        if method == "GET", path.hasSuffix("/matches/\(matchId)") {
            return FixtureResponse(statusCode: 200, data: matchDetailJSON(for: matchId))
        }

        if method == "GET", path.hasSuffix("/matches") || path.hasSuffix("/matches/") {
            return FixtureResponse(statusCode: 200, data: matchesListJSON)
        }

        if method == "GET", isMatchResourcePath(path, matchId: prepareMatchId), path.contains("/selectable-players") {
            return FixtureResponse(statusCode: 200, data: selectablePlayersJSON)
        }

        if method == "GET", isMatchResourcePath(path, matchId: createdMatchId), path.contains("/events") {
            return FixtureResponse(statusCode: 200, data: emptyListJSON)
        }

        if method == "GET", isMatchResourcePath(path, matchId: finishedMatchId), path.contains("/events") {
            return FixtureResponse(statusCode: 200, data: finishedMatchEventsJSON)
        }

        if method == "GET", isMatchResourcePath(path, matchId: matchId), path.contains("/events") {
            return FixtureResponse(statusCode: 200, data: emptyListJSON)
        }

        if method == "GET", path.contains("/matches/"), path.hasSuffix("/stats") {
            if isMatchResourcePath(path, matchId: finishedMatchId) {
                return FixtureResponse(statusCode: 200, data: finishedMatchStatsJSON)
            }
            return FixtureResponse(statusCode: 200, data: emptyMatchStatsJSON)
        }

        if method == "GET", path.contains("/quizzes/matches/\(finishedMatchId)") {
            return FixtureResponse(statusCode: 200, data: matchQuizzesListJSON)
        }

        if method == "GET", path.contains("/quizzes/matches/") {
            return FixtureResponse(statusCode: 200, data: emptyListJSON)
        }

        if method == "GET", path.contains("/quizzes/\(quizId)/user-submission") {
            return FixtureResponse(statusCode: 404, data: notFoundJSON)
        }

        if method == "GET", path.contains("/quizzes/\(quizId)/leaderboard") {
            return FixtureResponse(statusCode: 200, data: emptyQuizLeaderboardJSON)
        }

        if method == "GET", path.contains("/quizzes/\(quizId)") {
            return FixtureResponse(statusCode: 200, data: matchQuizDetailJSON)
        }

        if method == "GET", path.hasSuffix("/teams/search") {
            return FixtureResponse(statusCode: 200, data: teamSearchResultsJSON)
        }

        if method == "POST", isCreateTeamPath(path) {
            applyCreateTeamSave(from: request)
            return FixtureResponse(statusCode: 200, data: createdTeamJSON())
        }

        if method == "POST", path.contains("/teams/"), path.hasSuffix("/join-requests") {
            applyJoinRequestSave(from: request, path: path)
            return FixtureResponse(statusCode: 200, data: joinRequestCreatedJSON())
        }

        if method == "GET", path.hasSuffix("/users/me/join-requests") {
            return FixtureResponse(statusCode: 200, data: myJoinRequestsJSON())
        }

        if method == "GET", path.hasSuffix("/teams/me") {
            return FixtureResponse(statusCode: 200, data: teamsMeJSON)
        }

        if method == "GET", path.contains("/teams/"), path.contains("/guests") {
            return FixtureResponse(statusCode: 200, data: emptyListJSON)
        }

        if method == "GET", path.contains("/teams/"), path.contains("/invitations") {
            return FixtureResponse(statusCode: 200, data: emptyListJSON)
        }

        if method == "GET", path.contains("/teams/"), path.contains("/join-requests") {
            return FixtureResponse(statusCode: 200, data: emptyListJSON)
        }

        if method == "GET", path.contains("/compositions/team/") {
            return FixtureResponse(statusCode: 200, data: emptyListJSON)
        }

        if method == "GET", path.hasSuffix("/teams/\(teamId)") {
            return FixtureResponse(statusCode: 200, data: teamDetailJSON)
        }

        if method == "GET", path.hasSuffix("/me") {
            return FixtureResponse(statusCode: 200, data: meJSON)
        }

        if method == "GET", path.contains("/sport-profile") {
            if UITestLaunchArgument.scenario == .sportProfile {
                return FixtureResponse(statusCode: 404, data: notFoundJSON)
            }
            return FixtureResponse(statusCode: 200, data: sportProfileResponseJSON())
        }

        if method == "POST", path.contains("/sport-profile") {
            applySportProfileSave(from: request)
            return FixtureResponse(statusCode: 200, data: sportProfileResponseJSON())
        }

        if method == "POST", isCreateMatchPath(path) {
            return FixtureResponse(statusCode: 200, data: createdMatchJSON)
        }

        if method == "GET", path.contains("/notifications/unread-count") {
            return FixtureResponse(statusCode: 200, data: unreadCountJSON())
        }

        if method == "GET", path.contains("/notifications") {
            return FixtureResponse(
                statusCode: 200,
                data: UITestLaunchArgument.usesPopulatedNotifications
                    ? populatedNotificationsJSON
                    : emptyNotificationsJSON
            )
        }

        if method == "GET", path.contains("/seasons/available") {
            return FixtureResponse(statusCode: 200, data: emptySeasonsJSON)
        }

        if method == "GET", path.contains("/rankings") {
            return FixtureResponse(statusCode: 200, data: teamRankingsJSON)
        }

        if method == "GET", path.contains("/insights") {
            return FixtureResponse(statusCode: 200, data: teamInsightsJSON)
        }

        if method == "GET", path.contains("/duos") {
            return FixtureResponse(statusCode: 200, data: teamDuosJSON)
        }

        if method == "GET", path.contains("/teams/"), path.contains("/stats") {
            return FixtureResponse(statusCode: 200, data: teamSeasonStatsJSON)
        }

        if method == "GET", path.contains("/availability") {
            return FixtureResponse(statusCode: 200, data: emptyListJSON)
        }

        if method == "POST", path.contains("/auth/refresh-token") {
            return FixtureResponse(statusCode: 200, data: refreshTokenJSON)
        }

        return FixtureResponse(statusCode: 200, data: successJSON)
    }

    private static func isMatchResourcePath(_ path: String, matchId: String) -> Bool {
        path.hasSuffix("/matches/\(matchId)") || path.contains("/matches/\(matchId)/")
    }

    private static func isCreateMatchPath(_ path: String) -> Bool {
        path.hasSuffix("/matches") || path.hasSuffix("/matches/")
    }

    private static func isCreateTeamPath(_ path: String) -> Bool {
        guard path.hasSuffix("/teams") || path.hasSuffix("/teams/") else { return false }
        return !path.contains("/join-requests")
            && !path.contains("/guests")
            && !path.contains("/invitations")
    }

    private static func matchId(from path: String) -> String? {
        let components = path.split(separator: "/")
        guard let matchesIndex = components.firstIndex(of: "matches"),
              components.indices.contains(matchesIndex + 1) else {
            return nil
        }
        let value = String(components[matchesIndex + 1])
        return value.isEmpty ? nil : value
    }

    private static var availabilityByMatchId: [String: String] = [:]
    private static var matchEditOverrides: [String: (opponent: String, location: String)] = [:]
    private static var lastCreatedTeamName = "Ma Nouvelle Équipe"
    private static var pendingJoinRequestTeamName = "FC Search UI"

    private static func myAvailabilityStatus(for matchId: String) -> String {
        availabilityByMatchId[matchId] ?? "available"
    }

    private static func applyMyAvailability(from request: URLRequest, path: String) {
        guard let matchId = matchId(from: path) else { return }
        guard let body = request.httpBody,
              let object = try? JSONSerialization.jsonObject(with: body) as? [String: Any],
              let status = object["status"] as? String else {
            return
        }
        availabilityByMatchId[matchId] = status
    }

    private static func applyMatchPatch(from request: URLRequest, path: String) {
        guard let matchId = matchId(from: path),
              let body = request.httpBody,
              let object = try? JSONSerialization.jsonObject(with: body) as? [String: Any] else {
            return
        }

        let currentOpponent: String
        let currentLocation: String
        if matchId == prepareMatchId {
            currentOpponent = "Draft Opponent"
            currentLocation = "Draft Stadium"
        } else {
            currentOpponent = "Rival FC"
            currentLocation = "Stade Municipal"
        }

        let opponent = (object["opponentTeam"] as? String) ?? matchEditOverrides[matchId]?.opponent ?? currentOpponent
        let location = (object["location"] as? String) ?? matchEditOverrides[matchId]?.location ?? currentLocation
        matchEditOverrides[matchId] = (opponent: opponent, location: location)
    }

    private static func applyCreateTeamSave(from request: URLRequest) {
        guard let body = request.httpBody,
              let object = try? JSONSerialization.jsonObject(with: body) as? [String: Any],
              let name = object["name"] as? String,
              !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return
        }
        lastCreatedTeamName = name.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private static var hasPendingJoinRequest = false

    private static func applyJoinRequestSave(from request: URLRequest, path: String) {
        hasPendingJoinRequest = true
        if let teamId = path.split(separator: "/").dropLast().last.map(String.init),
           teamId == searchableTeamId {
            pendingJoinRequestTeamName = "FC Search UI"
        }
    }

    private static func myAvailabilityResponseJSON(for matchId: String) -> Data {
        let status = myAvailabilityStatus(for: matchId)
        return Data(
            """
            {"success":true,"data":{"status":"\(status)","source":"self"}}
            """.utf8
        )
    }

    private static var sportProfileJerseyNumber = 10
    private static var sportProfileStrongFoot = "right"
    private static var sportProfileAvailabilities = ["monday"]

    private static func applySportProfileSave(from request: URLRequest) {
        guard let body = request.httpBody, !body.isEmpty else { return }

        if let decoded = try? JSONDecoder().decode(SportProfileRequest.self, from: body) {
            if let jersey = decoded.jerseyNumber {
                sportProfileJerseyNumber = jersey
            }
            if let strongFoot = decoded.strongFoot {
                sportProfileStrongFoot = strongFoot
            }
            if let availabilities = decoded.availabilities, !availabilities.isEmpty {
                sportProfileAvailabilities = availabilities
            }
        } else if let object = try? JSONSerialization.jsonObject(with: body) as? [String: Any],
                  let availabilities = object["availabilities"] as? [String],
                  !availabilities.isEmpty {
            sportProfileAvailabilities = availabilities
        }

        if let bodyString = String(data: body, encoding: .utf8),
           bodyString.contains("tuesday"),
           !sportProfileAvailabilities.contains("tuesday") {
            sportProfileAvailabilities.append("tuesday")
        }
    }

    private static var sportProfileAvailabilitiesJSON: String {
        let values = sportProfileAvailabilities.map { "\"\($0)\"" }.joined(separator: ", ")
        return "[\(values)]"
    }

    private static func sportProfileResponseJSON() -> Data {
        Data(
            """
            {
              "success": true,
              "data": {
                "_id": "ui-test-sport-profile",
                "userId": "ui-test-user",
                "favoriteLeague": "ligue-1",
                "favoriteTeam": "AJ Auxerre",
                "strongFoot": "\(sportProfileStrongFoot)",
                "experienceLevel": 0,
                "favoritePositions": ["goalkeeper"],
                "playedPositions": ["goalkeeper"],
                "availabilities": \(sportProfileAvailabilitiesJSON),
                "isCompleted": true,
                "jerseyNumber": \(sportProfileJerseyNumber),
                "createdAt": "2026-01-01T00:00:00.000Z",
                "updatedAt": "2026-01-01T00:00:00.000Z"
              }
            }
            """.utf8
        )
    }

    private static let capabilitiesJSON = """
    {"canRespond":true,"canManageAvailability":false,"canManageComposition":false,"canPublish":false,"canStartMatch":false,"canManageEvents":false,"canUpdateScore":false,"canFinishMatch":false}
    """

    private static let adminCapabilitiesJSON = """
    {"canRespond":true,"canManageAvailability":true,"canManageComposition":true,"canPublish":true,"canStartMatch":true,"canManageEvents":true,"canUpdateScore":true,"canFinishMatch":true}
    """

    private static let loginJSON = Data(
        """
        {
          "success": true,
          "data": {
            "user": {
              "_id": "ui-test-user",
              "email": "uitest@levestaire.test",
              "firstName": "Test",
              "lastName": "UI",
              "emailVerified": true,
              "isActive": true
            },
            "token": "ui-test-access-token",
            "refreshToken": "ui-test-refresh-token"
          }
        }
        """.utf8
    )

    private static let registerJSON = Data(
        """
        {"success":true,"message":"Compte créé avec succès"}
        """.utf8
    )

    private static let passwordResetJSON = Data(
        """
        {"success":true,"message":"Un email de réinitialisation a été envoyé."}
        """.utf8
    )

    private static let teamSearchResultsJSON = Data(
        """
        {
          "success": true,
          "data": [{
            "_id": "\(searchableTeamId)",
            "name": "FC Search UI",
            "memberCount": 5,
            "isMember": false,
            "hasPendingJoinRequest": false
          }]
        }
        """.utf8
    )

    private static let selectablePlayersJSON = Data(
        """
        {
          "success": true,
          "data": [{
            "_id": "ui-test-user",
            "userId": "ui-test-user",
            "firstName": "Test",
            "lastName": "UI"
          }]
        }
        """.utf8
    )

    private static func createdTeamJSON() -> Data {
        Data(
            """
            {
              "success": true,
              "data": {
                "_id": "\(createdTeamId)",
                "name": "\(lastCreatedTeamName)",
                "description": "",
                "adminId": "ui-test-user",
                "currentUserRole": "admin",
                "memberCount": 1,
                "members": [{
                  "_id": "ui-test-user",
                  "userId": "ui-test-user",
                  "firstName": "Test",
                  "lastName": "UI",
                  "role": "admin",
                  "jerseyNumber": 10
                }]
              }
            }
            """.utf8
        )
    }

    private static func joinRequestCreatedJSON() -> Data {
        Data(
            """
            {
              "success": true,
              "data": {
                "_id": "ui-test-join-request-1",
                "teamId": "\(searchableTeamId)",
                "teamName": "\(pendingJoinRequestTeamName)",
                "status": "pending"
              }
            }
            """.utf8
        )
    }

    private static func myJoinRequestsJSON() -> Data {
        guard hasPendingJoinRequest else {
            return emptyListJSON
        }

        return Data(
            """
            {
              "success": true,
              "data": [{
                "_id": "ui-test-join-request-1",
                "teamId": "\(searchableTeamId)",
                "teamName": "\(pendingJoinRequestTeamName)",
                "status": "pending"
              }]
            }
            """.utf8
        )
    }

    private static var matchesListJSON: Data {
        Data(
            """
            {
              "success": true,
              "data": [
                {
                  "_id": "\(prepareMatchId)",
                  "title": "vs Draft Opponent",
                  "status": "draft",
                  "opponentTeam": "Draft Opponent",
                  "location": "Draft Stadium",
                  "homeTeamName": "FC Test UI",
                  "teamId": "\(teamId)",
                  "date": "2026-08-01",
                  "startTime": "19:00",
                  "capabilities": \(adminCapabilitiesJSON)
                },
                {
                  "_id": "\(matchId)",
                  "title": "vs Rival FC",
                  "status": "upcoming",
                  "opponentTeam": "Rival FC",
                  "location": "Stade Municipal",
                  "homeTeamName": "FC Test UI",
                  "teamId": "\(teamId)",
                  "date": "2026-07-15",
                  "startTime": "20:00",
                  "myAvailabilityStatus": "\(myAvailabilityStatus(for: matchId))",
                  "capabilities": \(capabilitiesJSON)
                },
                {
                  "_id": "\(finishedMatchId)",
                  "title": "vs Champions FC",
                  "status": "finished",
                  "opponentTeam": "Champions FC",
                  "location": "Stade Final",
                  "homeTeamName": "FC Test UI",
                  "teamId": "\(teamId)",
                  "date": "2026-06-01",
                  "startTime": "18:00",
                  "scoreHome": 2,
                  "scoreAway": 1,
                  "capabilities": \(capabilitiesJSON)
                }
              ],
              "pagination": {
                "page": 1,
                "limit": 10,
                "total": 3,
                "totalPages": 1,
                "hasNextPage": false
              }
            }
            """.utf8
        )
    }

    private static func matchDetailJSON(for matchId: String) -> Data {
        let opponent = matchEditOverrides[matchId]?.opponent ?? "Rival FC"
        let location = matchEditOverrides[matchId]?.location ?? "Stade Municipal"
        return Data(
            """
            {
              "success": true,
              "data": {
                "_id": "\(matchId)",
                "title": "vs \(opponent)",
                "status": "upcoming",
                "opponentTeam": "\(opponent)",
                "location": "\(location)",
                "homeTeamName": "FC Test UI",
                "teamId": "\(teamId)",
                "date": "2026-07-15",
                "startTime": "20:00",
                "myAvailabilityStatus": "\(myAvailabilityStatus(for: matchId))",
                "capabilities": \(capabilitiesJSON)
              }
            }
            """.utf8
        )
    }

    private static func prepareMatchDetailJSON() -> Data {
        let opponent = matchEditOverrides[prepareMatchId]?.opponent ?? "Draft Opponent"
        let location = matchEditOverrides[prepareMatchId]?.location ?? "Draft Stadium"
        return Data(
            """
            {
              "success": true,
              "data": {
                "_id": "\(prepareMatchId)",
                "title": "vs \(opponent)",
                "status": "draft",
                "opponentTeam": "\(opponent)",
                "location": "\(location)",
                "homeTeamName": "FC Test UI",
                "teamId": "\(teamId)",
                "date": "2026-08-01",
                "startTime": "19:00",
                "capabilities": \(adminCapabilitiesJSON)
              }
            }
            """.utf8
        )
    }

    private static var finishedMatchDetailJSON: Data {
        Data(
            """
            {
              "success": true,
              "data": {
                "_id": "\(finishedMatchId)",
                "title": "vs Champions FC",
                "status": "finished",
                "opponentTeam": "Champions FC",
                "location": "Stade Final",
                "homeTeamName": "FC Test UI",
                "teamId": "\(teamId)",
                "date": "2026-06-01",
                "startTime": "18:00",
                "scoreHome": 2,
                "scoreAway": 1,
                "capabilities": \(capabilitiesJSON)
              }
            }
            """.utf8
        )
    }

    private static let finishedMatchEventsJSON = Data(
        """
        {
          "success": true,
          "data": [{
            "_id": "ui-test-event-1",
            "type": "goal",
            "minute": 23,
            "player": {
              "_id": "ui-test-user",
              "firstName": "Test",
              "lastName": "UI"
            },
            "isActive": true
          }]
        }
        """.utf8
    )

    private static let finishedMatchStatsJSON = Data(
        """
        {
          "success": true,
          "data": {
            "matchId": "\(finishedMatchId)",
            "totals": { "goals": 2, "assists": 1 },
            "players": [{
              "user": {
                "_id": "ui-test-user",
                "firstName": "Test",
                "lastName": "UI"
              },
              "goals": 1,
              "assists": 1
            }]
          }
        }
        """.utf8
    )

    private static let emptyMatchStatsJSON = Data(
        """
        {"success":true,"data":{"totals":{},"players":[]}}
        """.utf8
    )

    private static let matchQuizzesListJSON = Data(
        """
        {
          "success": true,
          "data": [{
            "_id": "\(quizId)",
            "title": "Quiz du match",
            "status": "open"
          }]
        }
        """.utf8
    )

    private static let matchQuizDetailJSON = Data(
        """
        {
          "success": true,
          "data": {
            "_id": "\(quizId)",
            "matchId": "\(finishedMatchId)",
            "teamId": "\(teamId)",
            "title": "Quiz du match",
            "status": "open",
            "falseAnswersCount": 2,
            "eligibleUserIds": [],
            "questions": [],
            "progressStats": {
              "participantCount": 0,
              "completedCount": 0
            }
          }
        }
        """.utf8
    )

    private static let emptyQuizLeaderboardJSON = Data(
        """
        {"success":true,"data":{"entries":[],"counts":{"participants":0,"completed":0}}}
        """.utf8
    )

    private static let notFoundJSON = Data(
        """
        {"success":false,"message":"Not found"}
        """.utf8
    )

    private static let teamMembersJSON = """
    [
      {
        "_id": "ui-test-user",
        "userId": "ui-test-user",
        "firstName": "Test",
        "lastName": "UI",
        "email": "uitest@levestaire.test",
        "role": "admin",
        "jerseyNumber": 10
      },
      {
        "_id": "ui-test-player-2",
        "userId": "ui-test-player-2",
        "firstName": "Alex",
        "lastName": "Martin",
        "role": "player",
        "jerseyNumber": 7
      }
    ]
    """

    private static var teamsMeJSON: Data {
        Data(
            """
            {
              "success": true,
              "data": {
                "teams": [{
                  "_id": "\(teamId)",
                  "name": "FC Test UI",
                  "description": "Équipe de test pour les UI tests",
                  "adminId": "ui-test-user",
                  "currentUserRole": "admin",
                  "memberCount": 2,
                  "members": \(teamMembersJSON)
                }],
                "adminTeams": 1,
                "memberTeams": 1,
                "total": 1
              }
            }
            """.utf8
        )
    }

    private static var teamDetailJSON: Data {
        Data(
            """
            {
              "success": true,
              "data": {
                "_id": "\(teamId)",
                "name": "FC Test UI",
                "description": "Équipe de test pour les UI tests",
                "adminId": "ui-test-user",
                "currentUserRole": "admin",
                "memberCount": 2,
                "members": \(teamMembersJSON)
              }
            }
            """.utf8
        )
    }

    private static let emptyListJSON = Data(
        """
        {"success":true,"data":[]}
        """.utf8
    )

    private static let teamSeasonStatsJSON = Data(
        """
        {"success":true,"data":{"teamId":"ui-test-team-1","totals":{},"players":[]}}
        """.utf8
    )

    private static let teamRankingsJSON = Data(
        """
        {"success":true,"data":{"rankings":{"scorers":[],"assisters":[],"general":[]}}}
        """.utf8
    )

    private static let teamInsightsJSON = Data(
        """
        {"success":true,"data":{}}
        """.utf8
    )

    private static let teamDuosJSON = Data(
        """
        {"success":true,"data":{"duos":[]}}
        """.utf8
    )

    private static let meJSON = Data(
        """
        {
          "success": true,
          "data": {
            "_id": "ui-test-user",
            "email": "uitest@levestaire.test",
            "firstName": "Test",
            "lastName": "UI",
            "isActive": true,
            "emailVerified": true
          }
        }
        """.utf8
    )

    private static var createdMatchJSON: Data {
        Data(
            """
            {
              "success": true,
              "data": {
                "_id": "\(createdMatchId)",
                "title": "vs Test Opponent",
                "status": "draft",
                "opponentTeam": "Test Opponent",
                "location": "Stade Test",
                "homeTeamName": "FC Test UI",
                "teamId": "\(teamId)",
                "date": "2026-07-20",
                "startTime": "20:00",
                "capabilities": \(capabilitiesJSON)
              }
            }
            """.utf8
        )
    }

    private static var createdMatchDetailJSON: Data {
        createdMatchJSON
    }

    private static func unreadCountJSON() -> Data {
        let count = UITestLaunchArgument.usesPopulatedNotifications ? 1 : 0
        return Data("{\"success\":true,\"data\":{\"count\":\(count)}}".utf8)
    }

    private static let emptyNotificationsJSON = Data(
        """
        {"success":true,"data":[],"pagination":{"page":1,"limit":20,"total":0,"totalPages":1,"hasNextPage":false}}
        """.utf8
    )

    private static let populatedNotificationsJSON = Data(
        """
        {
          "success": true,
          "data": [{
            "_id": "ui-test-notification-1",
            "title": "Nouveau match programmé",
            "body": "Un match a été programmé contre Rival FC.",
            "type": "match_created",
            "category": "sport",
            "channels": ["in_app"],
            "isRead": false,
            "createdAt": "2026-06-29T10:00:00.000Z"
          }],
          "pagination": {
            "page": 1,
            "limit": 20,
            "total": 1,
            "totalPages": 1,
            "hasNextPage": false
          }
        }
        """.utf8
    )

    private static let emptySeasonsJSON = Data(
        """
        {"success":true,"data":[]}
        """.utf8
    )

    private static let emptySeasonStatsJSON = Data(
        """
        {"success":true,"data":{"matchesPlayed":0,"goals":0,"assists":0}}
        """.utf8
    )

    private static let emptyArrayJSON = Data("[]".utf8)
    private static let emptyObjectJSON = Data("{}".utf8)
    private static let successJSON = Data("{\"success\":true}".utf8)
    private static let refreshTokenJSON = Data(
        """
        {"success":true,"accessToken":"ui-test-access-token","refreshToken":"ui-test-refresh-token"}
        """.utf8
    )
}
