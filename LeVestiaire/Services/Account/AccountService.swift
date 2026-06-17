//
//  AccountService.swift
//  LeVestaire
//
//  Created by Corentin Robert on 16/06/2026.
//

import Foundation

final class AccountService {
    static let shared = AccountService(
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
    func requestAccountDeletion() async -> AccountActionResponse {
        await performAccountAction(path: APIEndpoints.accountDeletionRequest)
    }

    @MainActor
    func cancelAccountDeletion() async -> AccountActionResponse {
        await performAccountAction(path: APIEndpoints.accountDeletionCancel)
    }

    @MainActor
    private func performAccountAction(path: String) async -> AccountActionResponse {
        guard let accessToken = authService.authToken, !accessToken.isEmpty else {
            return AccountActionResponse(
                success: false,
                message: L10n.sessionRequired
            )
        }

        do {
            let (data, _) = try await client.request(
                path: path,
                method: "POST",
                headers: ["Authorization": "Bearer \(accessToken)"]
            )

            if let response = try? APIResponseDecoder.decode(AccountActionResponse.self, from: data) {
                if let user = response.data {
                    authService.updateCurrentUser(user)
                }
                return response
            }

            return AccountActionResponse(
                success: false,
                message: L10n.invalidApiResponse
            )
        } catch {
            return AccountActionResponse(
                success: false,
                message: error.localizedDescription
            )
        }
    }
}
