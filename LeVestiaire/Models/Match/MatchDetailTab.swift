//
//  MatchDetailTab.swift
//  LeVestaire
//

import Foundation

enum MatchDetailTab: String, CaseIterable, Identifiable, Hashable {
    case composition
    case events
    case statistics
    case quiz

    var id: String { rawValue }

    var title: String {
        switch self {
        case .composition:
            return L10n.text("composition")
        case .events:
            return L10n.text("events")
        case .statistics:
            return L10n.text("statistics")
        case .quiz:
            return L10n.text("quiz")
        }
    }

    var icon: String {
        switch self {
        case .composition:
            return "person.3.fill"
        case .events:
            return "clock.fill"
        case .statistics:
            return "chart.bar.fill"
        case .quiz:
            return "questionmark.circle.fill"
        }
    }
}

struct MatchDetailTabConfiguration: Equatable {
    let visibleTabs: [MatchDetailTab]
    let defaultTab: MatchDetailTab

    static func forMatch(_ match: MatchDetail, showsPrepareHub: Bool) -> MatchDetailTabConfiguration? {
        switch match.status {
        case .draft, .postponed:
            if showsPrepareHub { return nil }
            return MatchDetailTabConfiguration(
                visibleTabs: [.composition],
                defaultTab: .composition
            )
        case .upcoming:
            return MatchDetailTabConfiguration(
                visibleTabs: [.composition],
                defaultTab: .composition
            )
        case .ongoing:
            return MatchDetailTabConfiguration(
                visibleTabs: [.composition, .events, .statistics],
                defaultTab: .composition
            )
        case .finished:
            return MatchDetailTabConfiguration(
                visibleTabs: [.composition, .events, .statistics, .quiz],
                defaultTab: .composition
            )
        case .cancelled:
            guard match.composition != nil else { return nil }
            return MatchDetailTabConfiguration(
                visibleTabs: [.composition],
                defaultTab: .composition
            )
        }
    }
}
