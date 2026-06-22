//
//  AccountService.swift
//  LeVestaire
//
//  Created by Corentin Robert on 16/06/2026.
//

import Foundation

enum AccountServiceError: LocalizedError {
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
        do {
            let (data, response) = try await AuthenticatedAPIClient.performRequest(
                client: client,
                authService: authService,
                path: path,
                method: "POST"
            )

            try validate(response: response, data: data)

            if let decoded = try? APIResponseDecoder.decode(AccountActionResponse.self, from: data) {
                if let user = decoded.data {
                    authService.updateCurrentUser(user)
                }
                return decoded
            }

            return AccountActionResponse(
                success: false,
                message: L10n.invalidApiResponse
            )
        } catch let error as AccountServiceError {
            return AccountActionResponse(
                success: false,
                message: error.localizedDescription
            )
        } catch ServiceAuthError.unauthorized {
            return AccountActionResponse(
                success: false,
                message: L10n.sessionRequired
            )
        } catch {
            return AccountActionResponse(
                success: false,
                message: error.localizedDescription
            )
        }
    }

    private func validate(response: HTTPURLResponse, data: Data) throws {
        guard HTTPResponseValidator.isSuccess(response) else {
            throw AccountServiceError.requestFailed(
                HTTPResponseValidator.localizedErrorMessage(
                    from: data,
                    fallback: L10n.invalidApiResponse
                )
            )
        }
    }
}
