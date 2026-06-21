//
//  MatchStatus.swift
//  LeVestaire
//
//  Created by Corentin Robert on 17/06/2026.
//

import Foundation

enum MatchStatus: String, CaseIterable, Codable, Identifiable, Hashable {
    case draft
    case upcoming
    case ongoing
    case finished
    case cancelled
    case postponed

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .draft: return L10n.draft
        case .upcoming: return L10n.upcoming
        case .ongoing: return L10n.ongoing
        case .finished: return L10n.finished
        case .cancelled: return L10n.cancelled
        case .postponed: return L10n.postponed
        }
    }

    var isPreparationStatus: Bool {
        self == .draft || self == .postponed
    }
}
