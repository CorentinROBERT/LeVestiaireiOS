//
//  TeamViewModel+Stats.swift
//  LeVestaire
//

import Foundation

extension TeamViewModel {
    func onStatsSeasonChanged() async {
        await loadTeamStats()
        statsLoadedForTeamId = selectedTeamId
    }

    func onRankingSeasonChanged() async {
        await loadTeamRankings()
        rankingsLoadedForTeamId = selectedTeamId
    }

    func rankingEntries(for kind: TeamRankingKind) -> [RankingPlayerEntry] {
        guard let teamRankings else { return [] }
        switch kind {
        case .scorers:
            return teamRankings.scorers
        case .assisters:
            return teamRankings.assisters
        case .general:
            return teamRankings.general
        }
    }
}
