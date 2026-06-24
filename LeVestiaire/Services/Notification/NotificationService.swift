//
//  NotificationService.swift
//  LeVestaire
//

import Foundation

struct NotificationFetchCriteria {
    var page: Int = 1
    var limit: Int = 20
    var filter: NotificationFilter = .all
}

enum NotificationServiceError: LocalizedError {
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

final class NotificationService {
    static let shared = NotificationService(
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
    func fetchNotifications(criteria: NotificationFetchCriteria) async throws -> NotificationListResponse {
        let (data, response) = try await authorizedRequest(
            path: APIEndpoints.notifications,
            method: "GET",
            queryItems: queryItems(for: criteria)
        )
        try validate(
            response: response,
            data: data,
            fallback: L10n.text("errorLoadingNotifications")
        )
        return try APIResponseDecoder.decode(NotificationListResponse.self, from: data)
    }

    @MainActor
    func fetchUnreadCount() async throws -> Int {
        let (data, response) = try await authorizedRequest(
            path: APIEndpoints.notificationsUnreadCount,
            method: "GET"
        )
        try validate(
            response: response,
            data: data,
            fallback: L10n.text("errorLoadingNotifications")
        )
        return try NotificationDecoding.decodeUnreadCount(from: data)
    }

    @MainActor
    func markAsRead(notificationId: String) async throws {
        let (data, response) = try await authorizedRequest(
            path: APIEndpoints.notificationRead(notificationId),
            method: "PATCH"
        )
        try validate(
            response: response,
            data: data,
            fallback: L10n.text("errorMarking")
        )
    }

    @MainActor
    func markAllAsRead() async throws {
        let (data, response) = try await authorizedRequest(
            path: APIEndpoints.notificationsReadAll,
            method: "PATCH"
        )
        try validate(
            response: response,
            data: data,
            fallback: L10n.text("errorMarkingAll")
        )
    }

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
            throw NotificationServiceError.unauthorized
        }
    }

    private func queryItems(for criteria: NotificationFetchCriteria) -> [URLQueryItem] {
        var items: [URLQueryItem] = [
            URLQueryItem(name: "page", value: String(criteria.page)),
            URLQueryItem(name: "limit", value: String(criteria.limit))
        ]

        if criteria.filter == .unread {
            items.append(URLQueryItem(name: "unreadOnly", value: "true"))
            items.append(URLQueryItem(name: "isRead", value: "false"))
        }

        return items
    }

    private func validate(response: HTTPURLResponse, data: Data, fallback: String) throws {
        guard HTTPResponseValidator.isSuccess(response) else {
            throw NotificationServiceError.requestFailed(
                HTTPResponseValidator.localizedErrorMessage(from: data, fallback: fallback)
            )
        }
    }
}
