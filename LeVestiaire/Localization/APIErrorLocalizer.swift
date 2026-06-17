//
//  APIErrorLocalizer.swift
//  LeVestaire
//
//  Created by Corentin Robert on 17/06/2026.
//

import Foundation

enum APIErrorLocalizer {
    /// Résout un message API (`error.auth.invalid_credentials`) vers la clé ARB (`errorauthinvalidcredentials`).
    static func localized(_ raw: String?) -> String? {
        guard let raw else { return nil }

        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }

        guard looksLikeApiKey(trimmed) else { return trimmed }

        let key = normalizedKey(from: trimmed)
        let translated = String(
            localized: String.LocalizationValue(stringLiteral: key),
            locale: LocalizationManager.shared.locale
        )

        guard translated != key else { return nil }
        return translated
    }

    static func message(message: String?, error: String?, fallback: String) -> String {
        if let error, !error.isEmpty, let resolved = localized(error) {
            return resolved
        }
        if let message, !message.isEmpty, let resolved = localized(message) {
            return resolved
        }
        return fallback
    }

    private static func looksLikeApiKey(_ value: String) -> Bool {
        value.hasPrefix("error.") || value.hasPrefix("success.")
    }

    private static func normalizedKey(from apiKey: String) -> String {
        apiKey
            .replacingOccurrences(of: ".", with: "")
            .replacingOccurrences(of: "_", with: "")
            .lowercased()
    }
}
