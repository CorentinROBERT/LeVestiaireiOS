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
        let method = request.httpMethod ?? "GET"
        let url = request.url?.absoluteString ?? "—"
        let message = "→ \(method) \(url)"

        logger.info("\(message, privacy: .public)")

        #if DEBUG
        print("[API] \(message)")
        #endif
    }

    static func logResponse(
        request: URLRequest,
        response: HTTPURLResponse,
        data: Data,
        durationMs: Int
    ) {
        let method = request.httpMethod ?? "GET"
        let url = request.url?.absoluteString ?? "—"
        let body = bodyPreview(data)
        let message = "← HTTP \(response.statusCode) \(method) \(url) (\(durationMs) ms) body: \(body)"

        logger.info("\(message, privacy: .public)")

        #if DEBUG
        print("[API] \(message)")
        #endif
    }

    static func logFailure(request: URLRequest, error: Error, durationMs: Int) {
        let method = request.httpMethod ?? "GET"
        let url = request.url?.absoluteString ?? "—"
        let message = "✗ \(method) \(url) (\(durationMs) ms) error: \(error.localizedDescription)"

        logger.error("\(message, privacy: .public)")

        #if DEBUG
        print("[API] \(message)")
        #endif
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
