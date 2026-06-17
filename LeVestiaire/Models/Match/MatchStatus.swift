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
        case .upcoming: return L10n.upcoming
        case .ongoing: return L10n.ongoing
        case .finished: return L10n.finished
        case .cancelled: return L10n.cancelled
        case .postponed: return L10n.postponed
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
