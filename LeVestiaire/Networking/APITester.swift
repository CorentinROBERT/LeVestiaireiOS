//
//  APITester.swift
//  LeVestaire
//
//  Created by Corentin Robert on 12/06/2026.
//

import Foundation

struct APITestResult {
    let statusCode: Int
    let durationMs: Int
}

enum APITestError: LocalizedError {
    case emptyURL
    case invalidURL
    case invalidResponse

    var errorDescription: String? {
        switch self {
        case .emptyURL:
            return "L'URL est vide."
        case .invalidURL:
            return "L'URL n'est pas valide."
        case .invalidResponse:
            return "Réponse serveur invalide."
        }
    }
}

enum APITester {
    static func test(urlString: String, timeout: TimeInterval = 10) async throws -> APITestResult {
        let trimmedURL = urlString.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !trimmedURL.isEmpty else {
            throw APITestError.emptyURL
        }

        guard let url = URL(string: trimmedURL) else {
            throw APITestError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.timeoutInterval = timeout

        let start = Date()
        let (_, response) = try await APIClient.shared.perform(request)
        let durationMs = Int(Date().timeIntervalSince(start) * 1000)

        return APITestResult(statusCode: response.statusCode, durationMs: durationMs)
    }
}
