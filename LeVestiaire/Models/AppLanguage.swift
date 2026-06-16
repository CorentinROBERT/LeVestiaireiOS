//
//  AppLanguage.swift
//  LeVestaire
//
//  Created by Corentin Robert on 14/06/2026.
//

import Foundation

enum AppLanguage: String, CaseIterable, Identifiable {
    case french = "fr"
    case english = "en"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .french:
            return "Français"
        case .english:
            return "English"
        }
    }

    var locale: Locale {
        switch self {
        case .french:
            return Locale(identifier: "fr_FR")
        case .english:
            return Locale(identifier: "en_US")
        }
    }
}
