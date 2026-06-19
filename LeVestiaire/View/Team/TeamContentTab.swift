//
//  TeamContentTab.swift
//  LeVestaire
//

import Foundation

enum TeamContentTab: String, CaseIterable, Identifiable {
    case roster
    case stats
    case rankings
    case compositions

    var id: String { rawValue }

    var title: String {
        switch self {
        case .roster:
            return L10n.text("teamTabRoster")
        case .stats:
            return L10n.text("teamTabStats")
        case .rankings:
            return L10n.text("teamTabRankings")
        case .compositions:
            return L10n.text("teamTabCompositions")
        }
    }
}
