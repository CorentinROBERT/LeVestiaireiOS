//
//  AuthenticatedAPIClient.swift
//  LeVestaire
//

import Foundation

enum ServiceAuthError: Error {
    case unauthorized
}

enum HTTPResponseValidator {
    static func isSuccess(_ response: HTTPURLResponse) -> Bool {
        (200...299).contains(response.statusCode)
    }

    static func localizedErrorMessage(from data: Data, fallback: String) -> String {
        APIResponseDecoder.resolveErrorMessage(from: data, fallback: fallback) ?? fallback
    }
}

enum AuthenticatedAPIClient {
    static func bearerHeader(accessToken: String) -> [String: String] {
        ["Authorization": "Bearer \(accessToken)"]
    }

    @MainActor
    static func performRequest(
        client: APIClient,
        authService: AuthService,
        path: String,
        method: String,
        body: Data? = nil,
        queryItems: [URLQueryItem] = []
    ) async throws -> (Data, HTTPURLResponse) {
        guard let accessToken = authService.authToken, !accessToken.isEmpty else {
            throw ServiceAuthError.unauthorized
        }

        return try await client.request(
            path: path,
            method: method,
            body: body,
            headers: bearerHeader(accessToken: accessToken),
            queryItems: queryItems
        )
    }

    @MainActor
    static func performMultipartRequest(
        client: APIClient,
        authService: AuthService,
        path: String,
        method: String,
        fieldName: String,
        fileName: String,
        mimeType: String,
        fileData: Data,
        additionalFields: [String: String] = [:]
    ) async throws -> (Data, HTTPURLResponse) {
        guard let accessToken = authService.authToken, !accessToken.isEmpty else {
            throw ServiceAuthError.unauthorized
        }

        return try await client.uploadMultipart(
            path: path,
            method: method,
            fieldName: fieldName,
            fileName: fileName,
            mimeType: mimeType,
            fileData: fileData,
            headers: bearerHeader(accessToken: accessToken),
            additionalFields: additionalFields
        )
    }
}
