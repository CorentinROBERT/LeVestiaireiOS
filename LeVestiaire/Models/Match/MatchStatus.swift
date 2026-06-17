//
//  MatchStatus.swift
//  LeVestaire
//
//  Created by Corentin Robert on 17/06/2026.
//

import Foundation
import SwiftUI

enum MatchStatus: String, CaseIterable, Codable, Identifiable, Hashable {
    case upcoming
    case ongoing
    case finished
    case cancelled
    case postponed

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .upcoming: return "À venir"
        case .ongoing: return "En cours"
        case .finished: return "Terminé"
        case .cancelled: return "Annulé"
        case .postponed: return "Reporté"
        }
    }

    var color: Color {
        switch self {
        case .upcoming: return AppPalette.Primary.main
        case .ongoing: return AppPalette.Semantic.warning
        case .finished: return AppPalette.Semantic.success
        case .cancelled: return AppPalette.Semantic.error
        case .postponed: return AppPalette.Neutral.textTertiary
        }
    }
}
