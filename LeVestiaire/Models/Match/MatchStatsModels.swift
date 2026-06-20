//
//  MatchStatsModels.swift
//  LeVestaire
//

import Foundation

struct MatchStatsPayload: Decodable, Equatable {
    let matchId: String?
    let totals: TeamSeasonStatsTotals?
    let players: [TeamPlayerSeasonStats]?

    var resolvedTotals: TeamSeasonStatsTotals {
        if let totals, totals.hasAnyValue {
            return totals
        }
        return computedTotalsFromPlayers
    }

    var sortedPlayers: [TeamPlayerSeasonStats] {
        (players ?? []).sorted { lhs, rhs in
            if lhs.goals != rhs.goals { return lhs.goals > rhs.goals }
            if lhs.assists != rhs.assists { return lhs.assists > rhs.assists }
            return lhs.displayName.localizedCaseInsensitiveCompare(rhs.displayName) == .orderedAscending
        }
    }

    var hasContent: Bool {
        resolvedTotals.hasAnyValue || !(players?.isEmpty ?? true)
    }

    private var computedTotalsFromPlayers: TeamSeasonStatsTotals {
        let list = players ?? []
        return TeamSeasonStatsTotals(
            goals: list.reduce(0) { $0 + $1.goals },
            ownGoals: list.reduce(0) { $0 + $1.ownGoals },
            assists: list.reduce(0) { $0 + $1.assists },
            yellowCards: list.reduce(0) { $0 + $1.yellowCards },
            redCards: list.reduce(0) { $0 + $1.redCards },
            substitutionsIn: list.reduce(0) { $0 + $1.substitutionsIn },
            substitutionsOut: list.reduce(0) { $0 + $1.substitutionsOut },
            shotsOnTarget: list.reduce(0) { $0 + $1.shotsOnTarget },
            saves: list.reduce(0) { $0 + $1.saves },
            injuries: list.reduce(0) { $0 + $1.injuries },
            shlagCount: list.reduce(0) { $0 + $1.shlagCount },
            manOfTheMatchCount: list.reduce(0) { $0 + $1.manOfTheMatchCount },
            otherCount: list.reduce(0) { $0 + $1.otherCount }
        )
    }
}

extension TeamPlayerSeasonStats {
    var hasMatchStatistics: Bool {
        goals > 0
            || ownGoals > 0
            || assists > 0
            || yellowCards > 0
            || redCards > 0
            || substitutionsIn > 0
            || substitutionsOut > 0
            || shotsOnTarget > 0
            || saves > 0
            || injuries > 0
            || shlagCount > 0
            || manOfTheMatchCount > 0
            || otherCount > 0
    }

    var matchStatEntries: [(label: String, value: Int)] {
        var entries: [(label: String, value: Int)] = []
        if goals > 0 { entries.append((L10n.goals, goals)) }
        if ownGoals > 0 { entries.append((L10n.text("ownGoals"), ownGoals)) }
        if assists > 0 { entries.append((L10n.assists, assists)) }
        if yellowCards > 0 { entries.append((L10n.yellowCards, yellowCards)) }
        if redCards > 0 { entries.append((L10n.redCards, redCards)) }
        if substitutionsIn > 0 { entries.append((L10n.text("substitutionsIn"), substitutionsIn)) }
        if substitutionsOut > 0 { entries.append((L10n.text("substitutionsOut"), substitutionsOut)) }
        if shotsOnTarget > 0 { entries.append((L10n.shotsOnTarget, shotsOnTarget)) }
        if saves > 0 { entries.append((L10n.saves, saves)) }
        if injuries > 0 { entries.append((L10n.text("injury"), injuries)) }
        if shlagCount > 0 { entries.append((L10n.text("shlag"), shlagCount)) }
        if manOfTheMatchCount > 0 { entries.append((L10n.manOfTheMatch, manOfTheMatchCount)) }
        if otherCount > 0 { entries.append((L10n.text("other"), otherCount)) }
        return entries
    }
}

enum MatchStatsDecoding {
    static func decode(from data: Data) throws -> MatchStatsPayload {
        if let payload = try? APIResponseDecoder.decodePayload(MatchStatsPayload.self, from: data) {
            return payload
        }
        return try APIResponseDecoder.decode(MatchStatsPayload.self, from: data)
    }
}
