//
//  CompositionService.swift
//  LeVestaire
//

import Foundation

final class CompositionService {
    static let shared = CompositionService(
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
    func fetchTeamCompositions(teamId: String) async throws -> [TeamComposition] {
        let (data, response) = try await authorizedRequest(
            path: APIEndpoints.teamCompositions(teamId),
            method: "GET"
        )
        try validate(response: response, data: data)
        return try CompositionDecoding.decodeCompositions(from: data)
    }

    @MainActor
    func createComposition(_ request: CompositionSaveRequest) async throws -> TeamComposition {
        let body = try JSONEncoder().encode(request)
        let (data, response) = try await authorizedRequest(
            path: APIEndpoints.createComposition(),
            method: "POST",
            body: body
        )
        try validate(response: response, data: data)
        return try CompositionDecoding.decodeComposition(from: data)
    }

    @MainActor
    func updateComposition(id: String, request: CompositionSaveRequest) async throws -> TeamComposition {
        let body = try JSONEncoder().encode(request)
        let (data, response) = try await authorizedRequest(
            path: APIEndpoints.updateComposition(id),
            method: "PUT",
            body: body
        )
        try validate(response: response, data: data)
        return try CompositionDecoding.decodeComposition(from: data)
    }

    @MainActor
    func deleteComposition(id: String) async throws {
        let (data, response) = try await authorizedRequest(
            path: APIEndpoints.deleteComposition(id),
            method: "DELETE"
        )
        try validate(response: response, data: data)
    }

    @MainActor
    func deleteAlternativeFormation(compositionId: String, alternativeId: String) async throws {
        let (data, response) = try await authorizedRequest(
            path: APIEndpoints.deleteAlternativeFormation(
                compositionId: compositionId,
                altId: alternativeId
            ),
            method: "DELETE"
        )
        try validate(response: response, data: data)
    }

    @MainActor
    private func authorizedRequest(
        path: String,
        method: String,
        body: Data? = nil
    ) async throws -> (Data, HTTPURLResponse) {
        guard let accessToken = authService.authToken, !accessToken.isEmpty else {
            throw TeamServiceError.unauthorized
        }

        return try await client.request(
            path: path,
            method: method,
            body: body,
            headers: ["Authorization": "Bearer \(accessToken)"]
        )
    }

    private func validate(response: HTTPURLResponse, data: Data) throws {
        guard (200...299).contains(response.statusCode) else {
            let rawMessage = APIResponseDecoder.decodeErrorMessage(from: data)
            let message = L10n.apiMessage(rawMessage) ?? rawMessage ?? L10n.text("errorCompositionValidation")
            throw TeamServiceError.requestFailed(message)
        }
    }
}
