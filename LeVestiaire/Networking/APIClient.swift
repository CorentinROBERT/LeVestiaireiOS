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
            return "L'URL de base de l'API est invalide."
        case .invalidResponse:
            return "Réponse serveur invalide."
        }
    }
}

final class APIClient {
    static let shared = APIClient(
        configuration: APIConfiguration.shared,
        session: .shared
    )

    private let configuration: APIConfiguration
    private let session: URLSession

    init(configuration: APIConfiguration, session: URLSession = .shared) {
        self.configuration = configuration
        self.session = session
    }

    func request(
        path: String,
        method: String = "GET",
        body: Data? = nil,
        timeout: TimeInterval = 30,
        headers: [String: String] = [:]
    ) async throws -> (Data, HTTPURLResponse) {
        let base = configuration.resolvedBaseURL.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !base.isEmpty, let baseURL = URL(string: base) else {
            throw APIClientError.invalidBaseURL
        }

        let normalizedPath = path.hasPrefix("/") ? String(path.dropFirst()) : path
        let url = baseURL.appending(path: normalizedPath)

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

        return try await perform(request)
    }

    func perform(_ request: URLRequest) async throws -> (Data, HTTPURLResponse) {
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
}
