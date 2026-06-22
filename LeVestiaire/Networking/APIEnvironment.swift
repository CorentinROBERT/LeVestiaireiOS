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
            return L10n.productionEnvironment
        case .dev:
            return L10n.apiEnvironmentDev
        case .custom:
            return L10n.customUrl
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

    /// Environnement par défaut à la première installation (aucune valeur persistée).
    static var buildDefault: APIEnvironment {
        #if DEBUG
        .dev
        #else
        .production
        #endif
    }
}


