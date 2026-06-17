//
//  APILogger.swift
//  LeVestaire
//
//  Created by Corentin Robert on 14/06/2026.
//

import Foundation
import os

enum APILogger {
    private static let logger = Logger(
        subsystem: Bundle.main.bundleIdentifier ?? "LeVestaire",
        category: "API"
    )

    static func logRequest(_ request: URLRequest) {
        let message = "[LOG] \(requestLogMessage(for: request))"
        logger.info("\(message, privacy: .public)")
    }

    static func logResponse(
        request: URLRequest,
        response: HTTPURLResponse,
        data: Data,
        durationMs: Int
    ) {
        let requestLine = requestLogMessage(for: request)
        let body = bodyPreview(data)
        let message = "\(requestLine) → HTTP \(response.statusCode) (\(durationMs) ms) body: \(body)"

        logger.info("\(message, privacy: .sensitive)")
    }

    static func logFailure(request: URLRequest, error: Error, durationMs: Int) {
        let requestLine = requestLogMessage(for: request)
        let message = "\(requestLine) → error: \(error.localizedDescription) (\(durationMs) ms)"

        logger.error("\(message, privacy: .public)")
    }

    private static func requestLogMessage(for request: URLRequest) -> String {
        let method = (request.httpMethod ?? "GET").uppercased()
        let url = request.url?.absoluteString ?? "—"
        return "\(method) \(url)"
    }

    private static func bodyPreview(_ data: Data) -> String {
        guard !data.isEmpty else { return "(empty)" }

        let maxLength = 500
        if let string = String(data: data, encoding: .utf8) {
            if string.count <= maxLength {
                return string
            }
            return String(string.prefix(maxLength)) + "…"
        }

        return "<\(data.count) bytes>"
    }
}
