//
//  MatchEventsGrouped.swift
//  LeVestaire
//

import Foundation

private func matchEventTimelineRank(for type: MatchEventType) -> Int {
    switch type {
    case .matchStart:
        return 0
    case .matchEnd:
        return 2
    default:
        return 1
    }
}

private func matchEventTimelineSort(_ lhs: MatchEvent, _ rhs: MatchEvent) -> Bool {
    let rankDiff = matchEventTimelineRank(for: lhs.type) - matchEventTimelineRank(for: rhs.type)
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
        let sorted = events.sorted(by: matchEventTimelineSort)
        startEvents = sorted.filter { $0.type == .matchStart }
        endEvents = sorted.filter { $0.type == .matchEnd }
        middleEvents = sorted.filter { $0.type != .matchStart && $0.type != .matchEnd }
    }
}

extension Array where Element == MatchEvent {
    var groupedForTimeline: MatchEventsGrouped {
        MatchEventsGrouped(from: self)
    }
}
