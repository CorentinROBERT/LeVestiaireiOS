//
//  DeviceTokenService.swift
//  LeVestaire
//

import Foundation
import UIKit

enum DeviceTokenServiceError: LocalizedError {
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

final class DeviceTokenService {
    static let shared = DeviceTokenService(
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
    func registerFCMToken(_ token: String) async throws {
        let request = RegisterDeviceTokenRequest(
            token: token,
            platform: "ios",
            deviceId: UIDevice.current.identifierForVendor?.uuidString,
            appVersion: AppInfo.version,
            locale: LocalizationManager.shared.language.rawValue
        )
        let body = try JSONEncoder().encode(request)
        let (data, response) = try await authorizedRequest(
            path: APIEndpoints.deviceTokens,
            method: "POST",
            body: body
        )
        try validate(
            response: response,
            data: data,
            fallback: L10n.text("pushTokenRegistrationFailed")
        )
    }

    @MainActor
    func unregisterFCMToken(_ token: String) async throws {
        let body = try JSONEncoder().encode(UnregisterDeviceTokenRequest(token: token))
        let (data, response) = try await authorizedRequest(
            path: APIEndpoints.deviceTokens,
            method: "DELETE",
            body: body
        )
        try validate(
            response: response,
            data: data,
            fallback: L10n.text("pushTokenUnregistrationFailed")
        )
    }

    @MainActor
    func sendTestPushNotification() async throws -> TestPushNotificationResponse {
        let (data, response) = try await authorizedRequest(
            path: APIEndpoints.testPushNotification,
            method: "POST"
        )
        try validate(
            response: response,
            data: data,
            fallback: L10n.text("testPushNotificationFailed")
        )

        if let payload = try? APIResponseDecoder.decodePayload(TestPushNotificationResponse.self, from: data) {
            return payload
        }
        return try APIResponseDecoder.decode(TestPushNotificationResponse.self, from: data)
    }

    @MainActor
    private func authorizedRequest(
        path: String,
        method: String,
        body: Data? = nil
    ) async throws -> (Data, HTTPURLResponse) {
        do {
            return try await AuthenticatedAPIClient.performRequest(
                client: client,
                authService: authService,
                path: path,
                method: method,
                body: body
            )
        } catch ServiceAuthError.unauthorized {
            throw DeviceTokenServiceError.unauthorized
        }
    }

    private func validate(response: HTTPURLResponse, data: Data, fallback: String) throws {
        guard HTTPResponseValidator.isSuccess(response) else {
            throw DeviceTokenServiceError.requestFailed(
                HTTPResponseValidator.localizedErrorMessage(from: data, fallback: fallback)
            )
        }
    }
}
