//
//  APILogger.swift
//  LeVestaire
//

import Foundation
import os

enum APILogger {
    private static let logger = Logger(
        subsystem: Bundle.main.bundleIdentifier ?? "LeVestaire",
        category: "API"
    )

    private static let sensitiveKeys = [
        "accessToken",
        "refreshToken",
        "password",
        "authorization"
    ]

    static func logRequest(_ request: URLRequest) {
        #if DEBUG
        let message = "[LOG] \(requestLogMessage(for: request))"
        logger.debug("\(message, privacy: .public)")
        #endif
    }

    static func logResponse(
        request: URLRequest,
        response: HTTPURLResponse,
        data: Data,
        durationMs: Int
    ) {
        #if DEBUG
        let requestLine = requestLogMessage(for: request)
        let body = sanitizedBodyPreview(data)
        let message = "\(requestLine) → HTTP \(response.statusCode) (\(durationMs) ms) body: \(body)"
        logger.debug("\(message, privacy: .private)")
        #endif
    }

    static func logFailure(request: URLRequest, error: Error, durationMs: Int) {
        #if DEBUG
        let requestLine = requestLogMessage(for: request)
        let message = "\(requestLine) → error: \(error.localizedDescription) (\(durationMs) ms)"
        logger.error("\(message, privacy: .public)")
        #endif
    }

    private static func requestLogMessage(for request: URLRequest) -> String {
        let method = (request.httpMethod ?? "GET").uppercased()
        let url = request.url?.absoluteString ?? "—"
        return "\(method) \(url)"
    }

    private static func sanitizedBodyPreview(_ data: Data) -> String {
        guard !data.isEmpty else { return "(empty)" }

        let maxLength = 500
        if let string = String(data: data, encoding: .utf8) {
            let redacted = redactSensitiveValues(in: string)
            if redacted.count <= maxLength {
                return redacted
            }
            return String(redacted.prefix(maxLength)) + "…"
        }

        return "<\(data.count) bytes>"
    }

    private static func redactSensitiveValues(in json: String) -> String {
        var result = json
        for key in sensitiveKeys {
            let pattern = "(\"\(key)\"\\s*:\\s*\")([^\"]*)(\")"
            result = result.replacingOccurrences(
                of: pattern,
                with: "$1***$3",
                options: .regularExpression
            )
        }
        return result
    }
}
