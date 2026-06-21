//
//  MatchDetailViewModel+Statistics.swift
//  LeVestaire
//

import Foundation

extension MatchDetailViewModel {
    func loadMatchStatsIfNeeded(force: Bool = false) async {
        guard let match else { return }
        guard match.status == .ongoing || match.status == .finished else { return }
        guard force || !hasLoadedMatchStats else { return }

        isLoadingMatchStats = true
        defer { isLoadingMatchStats = false }

        do {
            matchStats = try await matchService.fetchMatchStats(matchId: matchId)
            hasLoadedMatchStats = true
        } catch {
            if isCancellationError(error) { return }
            matchStats = nil
            surfaceError(error)
        }
    }
}
