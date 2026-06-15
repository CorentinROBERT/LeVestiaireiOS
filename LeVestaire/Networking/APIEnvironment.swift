//
//  APIEnvironment.swift
//  LeVestaire
//
//  Created by Corentin Robert on 12/06/2026.
//

import Foundation

enum APIEnvironment: String, CaseIterable, Identifiable, Codable {
    case production
    case dev
    case custom

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .production:
            return "Production"
        case .dev:
            return "Dev"
        case .custom:
            return "Custom"
        }
    }

    var defaultBaseURL: String {
        switch self {
        case .production:
            return "https://api.squad-locker.com"
        case .dev:
            return "https://api.dev.squad-locker.com"
        case .custom:
            return ""
        }
    }
}


