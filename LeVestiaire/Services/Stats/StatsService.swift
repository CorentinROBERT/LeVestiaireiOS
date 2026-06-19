//
//  StatsService.swift
//  LeVestaire
//
//  Created by Corentin Robert on 16/06/2026.
//

import Foundation

enum StatsServiceError: LocalizedError {
    case unauthorized
    case requestFailed(String)

    var errorDescription: String? {
        switch self {
        case .unauthorized:
            return L10n.sessionRequired
        case .requestFailed(let message):
            return message
        }
    }
}

final class StatsService {
    static let shared = StatsService(
        client: APIClient.shared,
        authService: AuthService.shared
    )

    private let client: APIClient
    private let authService: AuthService

    init(client: APIClient, authService: AuthService) {
        self.client = client
        self.authService = authService
    }

    @MainActor
    func fetchAvailableSeasons() async -> [String] {
        guard let accessToken = authService.authToken, !accessToken.isEmpty else {
            return []
        }

        do {
            let (data, httpResponse) = try await client.request(
                path: APIEndpoints.availableSeasons,
                method: "GET",
                headers: authorizationHeader(accessToken: accessToken)
            )

            guard (200...299).contains(httpResponse.statusCode) else {
                return []
            }

            if let response = try? APIResponseDecoder.decode(AvailableSeasonsResponse.self, from: data),
               !response.seasons.isEmpty {
                return response.seasons
            }

            if let seasons = try? APIResponseDecoder.decodePayload([String].self, from: data),
               !seasons.isEmpty {
                return seasons
            }

            return []
        } catch {
            return []
        }
    }

    @MainActor
    func fetchUserSeasonStats(userId: String, season: String) async -> UserSeasonStats? {
        guard let accessToken = authService.authToken, !accessToken.isEmpty else {
            return nil
        }

        do {
            let (data, httpResponse) = try await client.request(
                path: APIEndpoints.userSeasonStats(userId: userId, season: season),
                method: "GET",
                headers: authorizationHeader(accessToken: accessToken)
            )

            guard (200...299).contains(httpResponse.statusCode) else {
                return nil
            }

            return try APIResponseDecoder.decodePayload(UserSeasonStats.self, from: data)
        } catch {
            return nil
        }
    }

    @MainActor
    func fetchTeamSeasonStats(teamId: String, season: String) async throws -> TeamSeasonStatsPayload? {
        guard let accessToken = authService.authToken, !accessToken.isEmpty else {
            throw StatsServiceError.unauthorized
        }

        let (data, httpResponse) = try await client.request(
            path: APIEndpoints.teamSeasonStats(teamId: teamId, season: season),
            method: "GET",
            headers: authorizationHeader(accessToken: accessToken)
        )

        guard (200...299).contains(httpResponse.statusCode) else {
            throw StatsServiceError.requestFailed(
                resolveErrorMessage(from: data, fallback: L10n.noStatisticsAvailable)
            )
        }

        return try APIResponseDecoder.decodePayload(TeamSeasonStatsPayload.self, from: data)
    }

    @MainActor
    func fetchTeamSeasonRankings(teamId: String, season: String) async throws -> TeamSeasonRankings? {
        guard let accessToken = authService.authToken, !accessToken.isEmpty else {
            throw StatsServiceError.unauthorized
        }

        let (data, httpResponse) = try await client.request(
            path: APIEndpoints.teamSeasonRankings(teamId: teamId, season: season),
            method: "GET",
            headers: authorizationHeader(accessToken: accessToken)
        )

        guard (200...299).contains(httpResponse.statusCode) else {
            throw StatsServiceError.requestFailed(
                resolveErrorMessage(from: data, fallback: L10n.noStatisticsAvailable)
            )
        }

        let payload = try APIResponseDecoder.decodePayload(TeamSeasonRankingsPayload.self, from: data)
        return payload.rankings
    }

    private func resolveErrorMessage(from data: Data, fallback: String) -> String {
        let rawMessage = APIResponseDecoder.decodeErrorMessage(from: data)
        return L10n.apiMessage(rawMessage) ?? rawMessage ?? fallback
    }

    private func authorizationHeader(accessToken: String) -> [String: String] {
        ["Authorization": "Bearer \(accessToken)"]
    }
}
