//
//  TeamStatsViewModel.swift
//  LeVestaire
//

import Combine
import Foundation

@MainActor
final class TeamStatsViewModel: ObservableObject {
    @Published var teamSeasonStats: TeamSeasonStatsPayload?
    @Published var teamInsights: TeamSeasonInsightsPayload?
    @Published var teamDuos: TeamSeasonDuosPayload?
    @Published var teamRankings: TeamSeasonRankings?
    @Published var availableSeasons: [String] = []
    @Published var selectedStatsSeason = ""
    @Published var selectedRankingSeason = ""
    @Published var selectedRankingKind: TeamRankingKind = .scorers
    @Published var isLoadingStats = false
    @Published var isLoadingInsights = false
    @Published var isLoadingDuos = false
    @Published var isLoadingRankings = false
    @Published var statsLoadError: String?
    @Published var insightsLoadError: String?
    @Published var duosLoadError: String?
    @Published var rankingsLoadError: String?

    private weak var host: TeamViewModel?
    private let statsService: any StatsServicing

    var statsLoadedForTeamId: String?
    var rankingsLoadedForTeamId: String?
    var seasonsTeamId: String?

    init(statsService: any StatsServicing) {
        self.statsService = statsService
    }

    func attach(to host: TeamViewModel) {
        self.host = host
    }

    func resetCache() {
        teamSeasonStats = nil
        teamInsights = nil
        teamDuos = nil
        teamRankings = nil
        availableSeasons = []
        selectedStatsSeason = ""
        selectedRankingSeason = ""
        statsLoadError = nil
        insightsLoadError = nil
        duosLoadError = nil
        rankingsLoadError = nil
        statsLoadedForTeamId = nil
        rankingsLoadedForTeamId = nil
        seasonsTeamId = nil
    }

    func invalidateLazyLoads() {
        statsLoadedForTeamId = nil
        rankingsLoadedForTeamId = nil
    }

    func loadIfNeeded(_ tab: TeamContentTab, force: Bool = false) async {
        guard let teamId = host?.selectedTeamId, !teamId.isEmpty else { return }

        switch tab {
        case .stats:
            if force || statsLoadedForTeamId != teamId {
                await loadStats()
                statsLoadedForTeamId = teamId
            }
        case .rankings:
            if force || rankingsLoadedForTeamId != teamId {
                await loadRankings()
                rankingsLoadedForTeamId = teamId
            }
        case .roster, .compositions:
            break
        }
    }

    func loadSeasonsIfNeeded() async {
        guard let teamId = host?.selectedTeamId, !teamId.isEmpty else {
            availableSeasons = []
            seasonsTeamId = nil
            return
        }

        guard seasonsTeamId != teamId else { return }

        availableSeasons = await statsService.fetchAvailableSeasons()
        let defaultSeason = SeasonFormatter.defaultSelection(from: availableSeasons)
        selectedStatsSeason = defaultSeason
        selectedRankingSeason = defaultSeason
        seasonsTeamId = teamId
    }

    func loadStats() async {
        guard let teamId = host?.selectedTeamId, !teamId.isEmpty, !selectedStatsSeason.isEmpty else {
            teamSeasonStats = nil
            teamInsights = nil
            teamDuos = nil
            statsLoadError = nil
            insightsLoadError = nil
            duosLoadError = nil
            return
        }

        isLoadingStats = true
        isLoadingInsights = true
        isLoadingDuos = true
        defer {
            isLoadingStats = false
            isLoadingInsights = false
            isLoadingDuos = false
        }

        async let statsTask: Void = loadSeasonStats(teamId: teamId, season: selectedStatsSeason)
        async let insightsTask: Void = loadSeasonInsights(teamId: teamId, season: selectedStatsSeason)
        async let duosTask: Void = loadSeasonDuos(teamId: teamId, season: selectedStatsSeason)
        _ = await (statsTask, insightsTask, duosTask)
    }

    func loadRankings() async {
        guard let teamId = host?.selectedTeamId, !teamId.isEmpty, !selectedRankingSeason.isEmpty else {
            teamRankings = nil
            rankingsLoadError = nil
            return
        }

        isLoadingRankings = true
        defer { isLoadingRankings = false }

        do {
            teamRankings = try await statsService.fetchTeamSeasonRankings(
                teamId: teamId,
                season: selectedRankingSeason
            )
            rankingsLoadError = nil
        } catch {
            teamRankings = nil
            rankingsLoadError = error.localizedDescription
        }
    }

    func onStatsSeasonChanged() async {
        await loadStats()
        statsLoadedForTeamId = host?.selectedTeamId
    }

    func onRankingSeasonChanged() async {
        await loadRankings()
        rankingsLoadedForTeamId = host?.selectedTeamId
    }

    func retryStats() async {
        await loadStats()
        statsLoadedForTeamId = host?.selectedTeamId
    }

    func retryRankings() async {
        await loadRankings()
        rankingsLoadedForTeamId = host?.selectedTeamId
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

    func clearLoadErrors() {
        statsLoadError = nil
        insightsLoadError = nil
        duosLoadError = nil
        rankingsLoadError = nil
    }

    func prepareForTeamChange() {
        if rankingsLoadedForTeamId != host?.selectedTeamId {
            teamRankings = nil
        }
    }

    private func loadSeasonStats(teamId: String, season: String) async {
        do {
            if var stats = try await statsService.fetchTeamSeasonStats(
                teamId: teamId,
                season: season
            ) {
                if let team = host?.selectedTeam {
                    stats = stats.enrichedWithRosterGuests(from: team)
                }
                teamSeasonStats = stats
            } else {
                teamSeasonStats = nil
            }
            statsLoadError = nil
        } catch {
            teamSeasonStats = nil
            statsLoadError = error.localizedDescription
        }
    }

    private func loadSeasonInsights(teamId: String, season: String) async {
        do {
            teamInsights = try await statsService.fetchTeamSeasonInsights(
                teamId: teamId,
                season: season
            )
            insightsLoadError = nil
        } catch {
            teamInsights = nil
            insightsLoadError = error.localizedDescription
        }
    }

    private func loadSeasonDuos(teamId: String, season: String) async {
        do {
            teamDuos = try await statsService.fetchTeamSeasonDuos(
                teamId: teamId,
                season: season
            )
            duosLoadError = nil
        } catch {
            teamDuos = nil
            duosLoadError = error.localizedDescription
        }
    }
}
