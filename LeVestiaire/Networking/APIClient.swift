//
//  APIClient.swift
//  LeVestaire
//
//  Created by Corentin Robert on 14/06/2026.
//

import Foundation

enum APIClientError: LocalizedError {
    case invalidBaseURL
    case invalidResponse

    var errorDescription: String? {
        switch self {
        case .invalidBaseURL:
            return L10n.invalidApiBaseUrl
        case .invalidResponse:
            return L10n.invalidServerResponse
        }
    }
}

final class APIClient {
    static let shared = APIClient(
        configuration: APIConfiguration.shared,
        session: .shared
    )

    private let configuration: APIConfiguration
    private var session: URLSession
    private weak var authInterceptor: APIAuthIntercepting?

    init(configuration: APIConfiguration, session: URLSession = .shared) {
        self.configuration = configuration
        self.session = session
    }

    func installUITestNetworkingIfNeeded() {
        guard UITestLaunchArgument.usesNetworkStub else { return }

        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [UITestURLProtocol.self]
        session = URLSession(configuration: configuration)
    }

    func setAuthInterceptor(_ interceptor: APIAuthIntercepting?) {
        authInterceptor = interceptor
    }

    func request(
        path: String,
        method: String = "GET",
        body: Data? = nil,
        timeout: TimeInterval = 30,
        headers: [String: String] = [:],
        queryItems: [URLQueryItem] = [],
        retryOnUnauthorized: Bool = true
    ) async throws -> (Data, HTTPURLResponse) {
        let base = configuration.resolvedBaseURL.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !base.isEmpty, let baseURL = URL(string: base) else {
            throw APIClientError.invalidBaseURL
        }

        let normalizedPath = path.hasPrefix("/") ? String(path.dropFirst()) : path
        var components = URLComponents(
            url: baseURL.appending(path: normalizedPath),
            resolvingAgainstBaseURL: false
        )
        if !queryItems.isEmpty {
            components?.queryItems = queryItems
        }

        guard let url = components?.url else {
            throw APIClientError.invalidBaseURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = method
        request.httpBody = body
        request.timeoutInterval = timeout

        if body != nil {
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        }

        for (key, value) in headers {
            request.setValue(value, forHTTPHeaderField: key)
        }

        return try await perform(request, retryOnUnauthorized: retryOnUnauthorized)
    }

    func uploadMultipart(
        path: String,
        method: String = "POST",
        fieldName: String,
        fileName: String,
        mimeType: String,
        fileData: Data,
        timeout: TimeInterval = 60,
        headers: [String: String] = [:],
        additionalFields: [String: String] = [:],
        retryOnUnauthorized: Bool = true
    ) async throws -> (Data, HTTPURLResponse) {
        let boundary = "Boundary-\(UUID().uuidString)"
        let base = configuration.resolvedBaseURL.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !base.isEmpty, let baseURL = URL(string: base) else {
            throw APIClientError.invalidBaseURL
        }

        let normalizedPath = path.hasPrefix("/") ? String(path.dropFirst()) : path
        let url = baseURL.appending(path: normalizedPath)

        var body = Data()
        for (key, value) in additionalFields {
            body.append("--\(boundary)\r\n")
            body.append("Content-Disposition: form-data; name=\"\(key)\"\r\n\r\n")
            body.append("\(value)\r\n")
        }
        body.append("--\(boundary)\r\n")
        body.append("Content-Disposition: form-data; name=\"\(fieldName)\"; filename=\"\(fileName)\"\r\n")
        body.append("Content-Type: \(mimeType)\r\n\r\n")
        body.append(fileData)
        body.append("\r\n")
        body.append("--\(boundary)--\r\n")

        var request = URLRequest(url: url)
        request.httpMethod = method
        request.httpBody = body
        request.timeoutInterval = timeout
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")

        for (key, value) in headers {
            request.setValue(value, forHTTPHeaderField: key)
        }

        return try await perform(request, retryOnUnauthorized: retryOnUnauthorized)
    }

    func perform(
        _ request: URLRequest,
        retryOnUnauthorized: Bool = true
    ) async throws -> (Data, HTTPURLResponse) {
        var (data, response) = try await performOnce(request)

        if retryOnUnauthorized,
           shouldRetryWithTokenRefresh(response: response, data: data, request: request) {
            if let newAccessToken = await refreshAccessTokenViaInterceptor() {
                var retryRequest = request
                retryRequest.setValue("Bearer \(newAccessToken)", forHTTPHeaderField: "Authorization")
                (data, response) = try await performOnce(retryRequest)
            } else {
                await forceLogoutViaInterceptor()
            }
        }

        return (data, response)
    }

    private func shouldRetryWithTokenRefresh(
        response: HTTPURLResponse,
        data: Data,
        request: URLRequest
    ) -> Bool {
        guard shouldAttemptTokenRefresh(for: request) else { return false }

        switch response.statusCode {
        case 401:
            return true
        case 403:
            return isTokenAuthenticationFailure(data: data)
        default:
            return false
        }
    }

    private func isTokenAuthenticationFailure(data: Data) -> Bool {
        struct ErrorEnvelope: Decodable {
            let error: String?
            let message: String?
        }

        guard let envelope = try? JSONDecoder().decode(ErrorEnvelope.self, from: data) else {
            return false
        }

        let text = [envelope.error, envelope.message]
            .compactMap { $0?.lowercased() }
            .joined(separator: " ")

        guard !text.isEmpty else { return false }

        if text.contains("error.auth") {
            return true
        }

        let mentionsToken = ["token", "jwt", "bearer"].contains { text.contains($0) }
        let mentionsFailure = ["invalid", "invalide", "expir", "unauthorized", "non autorisé"]
            .contains { text.contains($0) }

        return mentionsToken && mentionsFailure
    }

    private func performOnce(_ request: URLRequest) async throws -> (Data, HTTPURLResponse) {
        let start = Date()
        APILogger.logRequest(request)

        do {
            let (data, response) = try await session.data(for: request)
            let durationMs = Int(Date().timeIntervalSince(start) * 1000)

            guard let httpResponse = response as? HTTPURLResponse else {
                let error = APIClientError.invalidResponse
                APILogger.logFailure(request: request, error: error, durationMs: durationMs)
                throw error
            }

            APILogger.logResponse(
                request: request,
                response: httpResponse,
                data: data,
                durationMs: durationMs
            )

            return (data, httpResponse)
        } catch {
            let durationMs = Int(Date().timeIntervalSince(start) * 1000)
            APILogger.logFailure(request: request, error: error, durationMs: durationMs)
            throw error
        }
    }

    private func shouldAttemptTokenRefresh(for request: URLRequest) -> Bool {
        guard request.value(forHTTPHeaderField: "Authorization") != nil else {
            return false
        }

        guard let path = request.url?.path.lowercased() else {
            return false
        }

        let exemptPaths = [
            "/api/v1/auth/refresh-token",
            "/api/v1/auth/login",
            "/api/v1/auth/register",
            "/api/v1/auth/resend-verification",
            "/api/v1/auth/check-verification",
            "/api/v1/auth/request-password-reset",
            "/api/v1/auth/confirm-password-reset",
        ]

        return !exemptPaths.contains(where: { path.hasSuffix($0) })
    }

    @MainActor
    private func refreshAccessTokenViaInterceptor() async -> String? {
        await authInterceptor?.refreshAccessToken()
    }

    @MainActor
    private func forceLogoutViaInterceptor() async {
        await authInterceptor?.forceLogout()
    }
}

private extension Data {
    mutating func append(_ string: String) {
        guard let data = string.data(using: .utf8) else { return }
        append(data)
    }
}
