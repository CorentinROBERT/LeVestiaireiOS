//
//  MatchEventsGrouped.swift
//  LeVestaire
//

import Foundation

struct MatchEventsGrouped {
    let startEvents: [MatchEvent]
    let middleEvents: [MatchEvent]
    let endEvents: [MatchEvent]

    var hasBoundaries: Bool {
        !startEvents.isEmpty || !endEvents.isEmpty
    }

    var isEmpty: Bool {
        startEvents.isEmpty && middleEvents.isEmpty && endEvents.isEmpty
    }

    init(from events: [MatchEvent]) {
        let sorted = events.sorted(by: Self.timelineSort)
        startEvents = sorted.filter { $0.type == .matchStart }
        endEvents = sorted.filter { $0.type == .matchEnd }
        middleEvents = sorted.filter { $0.type != .matchStart && $0.type != .matchEnd }
    }

    private static func timelineSort(_ lhs: MatchEvent, _ rhs: MatchEvent) -> Bool {
        let rankDiff = timelineRank(for: lhs.type) - timelineRank(for: rhs.type)
        if rankDiff != 0 {
            return rankDiff < 0
        }

        let leftMinute = lhs.minute ?? Int.max
        let rightMinute = rhs.minute ?? Int.max
        if leftMinute != rightMinute {
            return leftMinute < rightMinute
        }

        let leftDate = lhs.createdAt ?? .distantPast
        let rightDate = rhs.createdAt ?? .distantPast
        return leftDate < rightDate
    }

    private static func timelineRank(for type: MatchEventType) -> Int {
        switch type {
        case .matchStart:
            return 0
        case .matchEnd:
            return 2
        default:
            return 1
        }
    }
}

extension Array where Element == MatchEvent {
    var groupedForTimeline: MatchEventsGrouped {
        MatchEventsGrouped(from: self)
    }
}
