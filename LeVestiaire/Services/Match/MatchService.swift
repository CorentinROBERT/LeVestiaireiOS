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
    var fromDate: Date?
    var toDate: Date?
}

enum MatchServiceError: LocalizedError {
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

    @MainActor
    func fetchMatches(criteria: MatchFetchCriteria) async throws -> MatchListResponse {
        guard let accessToken = authService.authToken, !accessToken.isEmpty else {
            throw MatchServiceError.unauthorized
        }

        let (data, httpResponse) = try await client.request(
            path: APIEndpoints.matches,
            headers: authorizationHeader(accessToken: accessToken),
            queryItems: queryItems(for: criteria)
        )

        guard (200...299).contains(httpResponse.statusCode) else {
            let rawMessage = APIResponseDecoder.decodeErrorMessage(from: data)
            let message = L10n.apiMessage(rawMessage) ?? rawMessage
                ?? L10n.loadMatchesFailedWithCode(httpResponse.statusCode)
            throw MatchServiceError.requestFailed(message)
        }

        return try APIResponseDecoder.decode(MatchListResponse.self, from: data)
    }

    private func queryItems(for criteria: MatchFetchCriteria) -> [URLQueryItem] {
        var items: [URLQueryItem] = [
            URLQueryItem(name: "page", value: String(criteria.page)),
            URLQueryItem(name: "limit", value: String(criteria.limit))
        ]

        for status in criteria.statuses.sorted(by: { $0.rawValue < $1.rawValue }) {
            items.append(URLQueryItem(name: "status", value: status.rawValue))
        }

        if let fromDate = criteria.fromDate {
            items.append(
                URLQueryItem(
                    name: "fromDate",
                    value: Self.apiDateFormatter.string(from: fromDate)
                )
            )
        }

        if let toDate = criteria.toDate {
            items.append(
                URLQueryItem(
                    name: "toDate",
                    value: Self.apiDateFormatter.string(from: toDate)
                )
            )
        }

        return items
    }

    private func authorizationHeader(accessToken: String) -> [String: String] {
        ["Authorization": "Bearer \(accessToken)"]
    }
}
