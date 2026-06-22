//
//  MatchDetailStatisticsViewModel.swift
//  LeVestaire
//

import Combine
import Foundation

@MainActor
final class MatchDetailStatisticsViewModel: ObservableObject {
    @Published var matchStats: MatchStatsPayload?
    @Published var isLoadingMatchStats = false
    @Published var hasLoadedMatchStats = false

    private weak var host: MatchDetailViewModel?
    private let matchService: MatchService

    init(matchService: MatchService) {
        self.matchService = matchService
    }

    func attach(to host: MatchDetailViewModel) {
        self.host = host
    }

    func resetCache() {
        hasLoadedMatchStats = false
        matchStats = nil
    }

    func loadIfNeeded(force: Bool = false) async {
        guard let match = host?.match else { return }
        guard match.status == .ongoing || match.status == .finished else { return }
        guard force || !hasLoadedMatchStats else { return }

        isLoadingMatchStats = true
        defer { isLoadingMatchStats = false }

        do {
            matchStats = try await matchService.fetchMatchStats(matchId: host?.matchId ?? "")
            hasLoadedMatchStats = true
        } catch {
            if isCancellationError(error) { return }
            matchStats = nil
            surfaceError(error)
        }
    }

    private func surfaceError(_ error: Error) {
        host?.surfaceError(error)
    }

    private func isCancellationError(_ error: Error) -> Bool {
        TaskCancellation.isError(error)
    }
}
