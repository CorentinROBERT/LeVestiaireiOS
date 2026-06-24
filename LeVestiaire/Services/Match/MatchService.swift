//
//  MatchService.swift
//  LeVestaire
//
//  Created by Corentin Robert on 17/06/2026.
//

import Foundation

struct MatchFetchCriteria {
    var page: Int = 1
    var limit: Int = 10
    var statuses: Set<MatchStatus> = []
    var teamIds: Set<String> = []
    var fromDate: Date?
    var toDate: Date?
}

/// Payload JSON passé dans `?criteria=...` sur `GET /api/v1/matches`.
private struct MatchListQueryCriteria: Encodable {
    var teamId: String?
    var status: StatusFilter?
    var from: String?
    var to: String?

    enum StatusFilter: Encodable {
        case single(String)
        case multiple([String])

        func encode(to encoder: Encoder) throws {
            var container = encoder.singleValueContainer()
            switch self {
            case .single(let value):
                try container.encode(value)
            case .multiple(let values):
                try container.encode(values)
            }
        }
    }
}

enum MatchServiceError: LocalizedError {
    case unauthorized
    case availabilityClosed
    case requestFailed(String)

    var errorDescription: String? {
        switch self {
        case .unauthorized:
            return L10n.sessionRequired
        case .availabilityClosed:
            return L10n.availabilityClosed
        case .requestFailed(let message):
            return message
        }
    }
}

final class MatchService {
    static let shared = MatchService(
        client: APIClient.shared,
        authService: AuthService.shared
    )

    private let client: APIClient
    private let authService: AuthService

    private static let apiDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }()

    init(client: APIClient, authService: AuthService) {
        self.client = client
        self.authService = authService
    }

    // MARK: - Listing & detail

    @MainActor
    func fetchMatches(criteria: MatchFetchCriteria) async throws -> MatchListResponse {
        let (data, httpResponse) = try await authorizedRequest(
            path: APIEndpoints.matches,
            method: "GET",
            queryItems: queryItems(for: criteria)
        )
        try validate(response: httpResponse, data: data, fallback: L10n.loadMatchesFailedWithCode(httpResponse.statusCode))
        return try APIResponseDecoder.decode(MatchListResponse.self, from: data)
    }

    @MainActor
    func fetchMatch(id: String, authenticated: Bool = true) async throws -> MatchDetail {
        let headers: [String: String]
        if authenticated, let accessToken = authService.authToken, !accessToken.isEmpty {
            headers = AuthenticatedAPIClient.bearerHeader(accessToken: accessToken)
        } else {
            headers = [:]
        }

        let (data, httpResponse) = try await client.request(
            path: APIEndpoints.getMatch(id),
            headers: headers
        )
        try validate(response: httpResponse, data: data, fallback: L10n.text("matchNotFound"))
        return try MatchDecoding.decodeDetail(from: data)
    }

    @MainActor
    func createMatch(request: CreateMatchRequest) async throws -> MatchDetail {
        let body = try JSONEncoder().encode(request)
        let (data, response) = try await authorizedRequest(
            path: APIEndpoints.createMatch(),
            method: "POST",
            body: body
        )
        try validate(response: response, data: data, fallback: L10n.text("errorMatchCannotBeModified"))
        return try MatchDecoding.decodeDetail(from: data)
    }

    @MainActor
    func updateMatch(id: String, request: UpdateMatchRequest) async throws -> MatchDetail {
        let body = try JSONEncoder().encode(request)
        let (data, response) = try await authorizedRequest(
            path: APIEndpoints.updateMatch(id),
            method: "PATCH",
            body: body
        )
        try validate(response: response, data: data, fallback: L10n.text("errorMatchCannotBeModified"))
        return try MatchDecoding.decodeDetail(from: data)
    }

    @MainActor
    func deleteMatch(id: String) async throws {
        let (data, response) = try await authorizedRequest(
            path: APIEndpoints.deleteMatch(id),
            method: "DELETE"
        )
        try validate(response: response, data: data, fallback: L10n.text("errorMatchCannotBeDeleted"))
    }

    // MARK: - Mode Répondre

    @MainActor
    func fetchMyAvailability(matchId: String) async throws -> MyAvailabilityResponse {
        let (data, response) = try await authorizedRequest(
            path: APIEndpoints.matchAvailabilityMe(matchId),
            method: "GET"
        )
        try validate(response: response, data: data, fallback: L10n.matchesLoading)
        if let payload = try? APIResponseDecoder.decodePayload(MyAvailabilityResponse.self, from: data) {
            return payload
        }
        return try APIResponseDecoder.decode(MyAvailabilityResponse.self, from: data)
    }

    @MainActor
    func updateMyAvailability(matchId: String, status: MatchAvailabilityStatus) async throws -> MyAvailabilityResponse {
        let body = try JSONEncoder().encode(UpdateMyAvailabilityRequest(status: status))
        let (data, response) = try await authorizedRequest(
            path: APIEndpoints.matchAvailabilityMe(matchId),
            method: "PUT",
            body: body
        )
        try validateAvailability(response: response, data: data, fallback: L10n.text("errorMatchCannotBeModified"))
        if let payload = try? APIResponseDecoder.decodePayload(MyAvailabilityResponse.self, from: data) {
            return payload
        }
        return try APIResponseDecoder.decode(MyAvailabilityResponse.self, from: data)
    }

    // MARK: - Mode Préparer

    @MainActor
    func fetchAvailability(matchId: String) async throws -> [MatchAvailabilityEntry] {
        let (data, response) = try await authorizedRequest(
            path: APIEndpoints.matchAvailability(matchId),
            method: "GET"
        )
        try validate(response: response, data: data, fallback: L10n.matchesLoading)
        return try MatchDecoding.decodeAvailabilityList(from: data)
    }

    @MainActor
    func fetchAvailabilityRoster(matchId: String) async throws -> MatchAvailabilityRoster {
        let (data, response) = try await authorizedRequest(
            path: APIEndpoints.matchAvailabilityRoster(matchId),
            method: "GET"
        )
        try validate(response: response, data: data, fallback: L10n.matchesLoading)
        return try MatchDecoding.decodeAvailabilityRoster(from: data)
    }

    @MainActor
    func forcePlayerAvailability(
        matchId: String,
        playerId: String,
        status: MatchAvailabilityStatus
    ) async throws -> MatchAvailabilityEntry {
        let body = try JSONEncoder().encode(ForcePlayerAvailabilityRequest(status: status))
        let (data, response) = try await authorizedRequest(
            path: APIEndpoints.matchAvailabilityPlayer(matchId, playerId: playerId),
            method: "PUT",
            body: body
        )
        try validateAvailability(response: response, data: data, fallback: L10n.text("errorMatchCannotBeModified"))
        if let entry = try? APIResponseDecoder.decodePayload(MatchAvailabilityEntry.self, from: data) {
            return entry
        }
        return try APIResponseDecoder.decode(MatchAvailabilityEntry.self, from: data)
    }

    @MainActor
    func fetchSelectablePlayers(matchId: String) async throws -> [MatchSelectablePlayer] {
        let (data, response) = try await authorizedRequest(
            path: APIEndpoints.matchSelectablePlayers(matchId),
            method: "GET"
        )
        try validate(response: response, data: data, fallback: L10n.matchesLoading)
        return try MatchDecoding.decodeSelectablePlayers(from: data)
    }

    @MainActor
    func createMatchComposition(matchId: String, request: MatchCompositionSaveRequest) async throws -> MatchDetail {
        let body = try JSONEncoder().encode(request)
        let (data, response) = try await authorizedRequest(
            path: APIEndpoints.matchComposition(matchId),
            method: "POST",
            body: body
        )
        try validate(response: response, data: data, fallback: L10n.text("errorMatchCannotBeModified"))
        return try MatchDecoding.decodeDetail(from: data)
    }

    @MainActor
    func updateMatchComposition(matchId: String, request: MatchCompositionSaveRequest) async throws -> MatchDetail {
        let body = try JSONEncoder().encode(request)
        let (data, response) = try await authorizedRequest(
            path: APIEndpoints.matchComposition(matchId),
            method: "PATCH",
            body: body
        )
        try validate(response: response, data: data, fallback: L10n.text("errorMatchCannotBeModified"))
        return try MatchDecoding.decodeDetail(from: data)
    }

    @MainActor
    func lockMatchComposition(matchId: String) async throws -> MatchDetail {
        let (data, response) = try await authorizedRequest(
            path: APIEndpoints.matchLockComposition(matchId),
            method: "POST"
        )
        try validate(response: response, data: data, fallback: L10n.text("errorMatchCannotBeModified"))
        return try MatchDecoding.decodeDetail(from: data)
    }

    @MainActor
    func publishMatch(id: String) async throws -> MatchDetail {
        try await updateMatchStatus(id: id, status: .upcoming)
    }

    // MARK: - Mode Animer

    @MainActor
    func updateMatchStatus(id: String, status: MatchStatus) async throws -> MatchDetail {
        let body = try JSONEncoder().encode(UpdateMatchStatusRequest(status: status))
        let (data, response) = try await authorizedRequest(
            path: APIEndpoints.updateMatchStatus(id),
            method: "PATCH",
            body: body
        )
        try validate(response: response, data: data, fallback: L10n.text("errorMatchCannotBeModified"))
        return try MatchDecoding.decodeDetail(from: data)
    }

    @MainActor
    func startMatch(id: String) async throws -> MatchDetail {
        try await updateMatchStatus(id: id, status: .ongoing)
    }

    @MainActor
    func finishMatch(id: String) async throws -> MatchDetail {
        try await updateMatchStatus(id: id, status: .finished)
    }

    @MainActor
    func fetchMatchStats(matchId: String) async throws -> MatchStatsPayload {
        let (data, response) = try await authorizedRequest(
            path: APIEndpoints.matchStats(matchId),
            method: "GET"
        )
        try validate(response: response, data: data, fallback: L10n.matchesLoading)
        return try MatchStatsDecoding.decode(from: data)
    }

    @MainActor
    func fetchQuizzesForMatch(matchId: String) async throws -> [MatchQuizSummary] {
        let (data, response) = try await authorizedRequest(
            path: APIEndpoints.quizzesForMatch(matchId),
            method: "GET"
        )
        try validate(response: response, data: data, fallback: L10n.matchesLoading)
        return try MatchQuizDecoding.decodeList(from: data)
    }

    @MainActor
    func fetchEvents(matchId: String) async throws -> [MatchEvent] {
        let (data, response) = try await authorizedRequest(
            path: APIEndpoints.matchEvents(matchId),
            method: "GET"
        )
        try validate(response: response, data: data, fallback: L10n.matchesLoading)
        return try MatchDecoding.decodeEvents(from: data)
    }

    @MainActor
    func createEvent(matchId: String, request: CreateMatchEventRequest) async throws -> MatchEvent {
        let body = try JSONEncoder().encode(request)
        let (data, response) = try await authorizedRequest(
            path: APIEndpoints.matchEvents(matchId),
            method: "POST",
            body: body
        )
        try validate(response: response, data: data, fallback: L10n.text("errorMatchCannotBeModified"))
        if let event = try? APIResponseDecoder.decodePayload(MatchEvent.self, from: data) {
            return event
        }
        return try APIResponseDecoder.decode(MatchEvent.self, from: data)
    }

    @MainActor
    func updateEvent(
        matchId: String,
        eventId: String,
        request: UpdateMatchEventRequest
    ) async throws -> MatchEvent {
        let body = try JSONEncoder().encode(request)
        let (data, response) = try await authorizedRequest(
            path: APIEndpoints.matchEventById(matchId: matchId, eventId: eventId),
            method: "PATCH",
            body: body
        )
        try validate(response: response, data: data, fallback: L10n.text("errorMatchCannotBeModified"))
        if let event = try? APIResponseDecoder.decodePayload(MatchEvent.self, from: data) {
            return event
        }
        return try APIResponseDecoder.decode(MatchEvent.self, from: data)
    }

    @MainActor
    func deleteEvent(matchId: String, eventId: String) async throws {
        let (data, response) = try await authorizedRequest(
            path: APIEndpoints.matchEventById(matchId: matchId, eventId: eventId),
            method: "DELETE"
        )
        try validate(response: response, data: data, fallback: L10n.text("errorMatchCannotBeModified"))
    }

    @MainActor
    func updateScore(matchId: String, scoreHome: Int, scoreAway: Int) async throws -> MatchDetail {
        let body = try JSONEncoder().encode(
            UpdateMatchScoreRequest(scoreHome: scoreHome, scoreAway: scoreAway)
        )
        let (data, response) = try await authorizedRequest(
            path: APIEndpoints.updateMatchScore(matchId),
            method: "PATCH",
            body: body
        )
        try validate(response: response, data: data, fallback: L10n.text("errorMatchCannotBeModified"))
        return try MatchDecoding.decodeDetail(from: data)
    }

    // MARK: - Helpers

    static func apiDateString(from date: Date) -> String {
        apiDateFormatter.string(from: date)
    }

    static func apiTimeString(from date: Date) -> String {
        apiTimeFormatter.string(from: date)
    }

    static let defaultMatchTime = "20:00"

    private static let apiTimeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "HH:mm"
        return formatter
    }()

    @MainActor
    private func authorizedRequest(
        path: String,
        method: String,
        body: Data? = nil,
        queryItems: [URLQueryItem] = []
    ) async throws -> (Data, HTTPURLResponse) {
        do {
            return try await AuthenticatedAPIClient.performRequest(
                client: client,
                authService: authService,
                path: path,
                method: method,
                body: body,
                queryItems: queryItems
            )
        } catch ServiceAuthError.unauthorized {
            throw MatchServiceError.unauthorized
        }
    }

    private func queryItems(for criteria: MatchFetchCriteria) -> [URLQueryItem] {
        var items: [URLQueryItem] = [
            URLQueryItem(name: "page", value: String(criteria.page)),
            URLQueryItem(name: "limit", value: String(criteria.limit))
        ]

        if let apiCriteria = matchListQueryCriteria(from: criteria),
           let data = try? JSONEncoder().encode(apiCriteria),
           let json = String(data: data, encoding: .utf8) {
            items.append(URLQueryItem(name: "criteria", value: json))
        }

        return items
    }

    private func matchListQueryCriteria(from criteria: MatchFetchCriteria) -> MatchListQueryCriteria? {
        let sortedStatuses = criteria.statuses.sorted { $0.rawValue < $1.rawValue }.map(\.rawValue)
        let status: MatchListQueryCriteria.StatusFilter? = switch sortedStatuses.count {
        case 0: nil
        case 1: .single(sortedStatuses[0])
        default: .multiple(sortedStatuses)
        }

        // L'API n'accepte qu'un seul teamId dans criteria ; le multi-équipe est affiné côté client.
        let teamId = criteria.teamIds.count == 1 ? criteria.teamIds.first : nil
        let from = criteria.fromDate.map { Self.apiDateFormatter.string(from: $0) }
        let to = criteria.toDate.map { Self.apiDateFormatter.string(from: $0) }

        guard status != nil || teamId != nil || from != nil || to != nil else {
            return nil
        }

        return MatchListQueryCriteria(teamId: teamId, status: status, from: from, to: to)
    }

    private func validate(response: HTTPURLResponse, data: Data, fallback: String) throws {
        guard HTTPResponseValidator.isSuccess(response) else {
            throw MatchServiceError.requestFailed(
                HTTPResponseValidator.localizedErrorMessage(from: data, fallback: fallback)
            )
        }
    }

    private func validateAvailability(response: HTTPURLResponse, data: Data, fallback: String) throws {
        guard HTTPResponseValidator.isSuccess(response) else {
            let rawMessage = APIResponseDecoder.decodeErrorMessage(from: data)
            if rawMessage == MatchAPIErrorCode.availabilityClosed.rawValue {
                throw MatchServiceError.availabilityClosed
            }
            throw MatchServiceError.requestFailed(
                HTTPResponseValidator.localizedErrorMessage(from: data, fallback: fallback)
            )
        }
    }
}
