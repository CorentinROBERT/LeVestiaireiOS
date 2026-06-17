//
//  RemoteMediaURL.swift
//  LeVestaire
//
//  Created by Corentin Robert on 17/06/2026.
//

import Foundation

enum RemoteMediaURL {
    static func resolve(_ raw: String?) -> String? {
        guard let raw else { return nil }

        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }

        if trimmed.hasPrefix("http://") || trimmed.hasPrefix("https://") {
            return trimmed
        }

        let base = APIConfiguration.shared.resolvedBaseURL
            .trimmingCharacters(in: .whitespacesAndNewlines)
        guard !base.isEmpty else { return trimmed }

        if trimmed.hasPrefix("/") {
            return base + trimmed
        }

        return "\(base)/\(trimmed)"
    }
}
