//
//  TeamKPIDisplay.swift
//  LeVestaire
//

import Foundation

enum TeamKPIDisplay {
    static let unavailableValue = "—"

    static func statValue(
        from stats: TeamSeasonStatsPayload?,
        hasError: Bool,
        isLoading: Bool,
        value: (TeamSeasonStatsPayload) -> Int
    ) -> String {
        if hasError, stats == nil, !isLoading {
            return unavailableValue
        }
        guard let stats else { return "0" }
        return "\(value(stats))"
    }

    static func matchesPlayed(
        stats: TeamSeasonStatsPayload?,
        hasError: Bool,
        isLoading: Bool
    ) -> String {
        statValue(from: stats, hasError: hasError, isLoading: isLoading) { $0.totalMatchesPlayed }
    }

    static func goals(
        stats: TeamSeasonStatsPayload?,
        hasError: Bool,
        isLoading: Bool
    ) -> String {
        statValue(from: stats, hasError: hasError, isLoading: isLoading) { $0.totals.goals }
    }

    static func assists(
        stats: TeamSeasonStatsPayload?,
        hasError: Bool,
        isLoading: Bool
    ) -> String {
        statValue(from: stats, hasError: hasError, isLoading: isLoading) { $0.totals.assists }
    }

    static func statsUnavailable(
        stats: TeamSeasonStatsPayload?,
        hasError: Bool,
        isLoading: Bool
    ) -> Bool {
        hasError && stats == nil && !isLoading
    }
}

#if DEBUG
enum TeamKPIDisplaySelfTest {
    static func run() {
        assert(TeamKPIDisplay.matchesPlayed(stats: nil, hasError: true, isLoading: false) == "—")
        assert(TeamKPIDisplay.matchesPlayed(stats: nil, hasError: false, isLoading: false) == "0")
    }
}
#endif
