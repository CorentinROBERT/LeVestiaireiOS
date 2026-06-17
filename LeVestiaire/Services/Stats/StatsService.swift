//
//  StatsService.swift
//  LeVestaire
//
//  Created by Corentin Robert on 16/06/2026.
//

import Foundation

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

            if let seasons = try? APIResponseDecoder.decode([String].self, from: data) {
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

            return try APIResponseDecoder.decode(UserSeasonStats.self, from: data)
        } catch {
            return nil
        }
    }

    private func authorizationHeader(accessToken: String) -> [String: String] {
        ["Authorization": "Bearer \(accessToken)"]
    }
}
