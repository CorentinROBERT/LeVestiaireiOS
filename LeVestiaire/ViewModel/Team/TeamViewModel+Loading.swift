//
//  TeamViewModel+Loading.swift
//  LeVestaire
//

import Foundation

extension TeamViewModel {
    func loadInitialData() async {
        errorMessage = nil
        isLoading = true
        defer { isLoading = false }

        do {
            let response = try await teamService.fetchMyTeams()
            teams = response.teams
            restoreSelection()
            await refreshSelectedTeamContent()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func refresh(currentTab: TeamContentTab = .roster) async {
        await executeRefresh(currentTab: currentTab)
    }

    func refreshFromPullToRefresh(currentTab: TeamContentTab = .roster) async {
        await pullToRefreshTask.perform { [weak self] in
            await self?.executeRefresh(currentTab: currentTab)
        }
    }

    private func executeRefresh(currentTab: TeamContentTab) async {
        invalidateLazyTabLoads()
        await loadInitialData()
        await loadTabContentIfNeeded(currentTab, force: true)
    }

    func onTeamSelectionChanged() async {
        selectedTeamStore.selectedTeamId = selectedTeamId
        invalidateLazyTabLoads()
        await refreshSelectedTeamContent()
    }

    func loadTabContentIfNeeded(_ tab: TeamContentTab, force: Bool = false) async {
        guard !selectedTeamId.isEmpty else { return }

        switch tab {
        case .roster:
            break
        case .stats:
            if force || statsLoadedForTeamId != selectedTeamId {
                await loadTeamStats()
                statsLoadedForTeamId = selectedTeamId
            }
        case .rankings:
            if force || rankingsLoadedForTeamId != selectedTeamId {
                await loadTeamRankings()
                rankingsLoadedForTeamId = selectedTeamId
            }
        case .compositions:
            if force || compositionsLoadedForTeamId != selectedTeamId {
                await loadCompositions()
                compositionsLoadedForTeamId = selectedTeamId
            }
        }
    }

    func retryTeamDetail() async {
        await refreshSelectedTeamContent()
    }

    func retryStats() async {
        await loadTeamStats()
        statsLoadedForTeamId = selectedTeamId
    }

    func retryRankings() async {
        await loadTeamRankings()
        rankingsLoadedForTeamId = selectedTeamId
    }

    func retryCompositions() async {
        await loadCompositions()
        compositionsLoadedForTeamId = selectedTeamId
    }

    func retryInvitations() async {
        await loadTeamInvitations()
    }

    func invalidateLazyTabLoads() {
        statsLoadedForTeamId = nil
        rankingsLoadedForTeamId = nil
        compositionsLoadedForTeamId = nil
    }

    func restoreSelection() {
        if let storedId = selectedTeamStore.selectedTeamId,
           teams.contains(where: { $0.id == storedId }) {
            selectedTeamId = storedId
            return
        }

        selectedTeamId = teams.first?.id ?? ""
    }

    func refreshSelectedTeamContent() async {
        guard !selectedTeamId.isEmpty else {
            selectedTeam = nil
            compositions = []
            teamSeasonStats = nil
            teamRankings = nil
            teamInvitations = []
            clearSectionLoadErrors()
            return
        }

        isRefreshingTeam = true
        defer { isRefreshingTeam = false }

        do {
            async let teamTask = teamService.fetchTeam(id: selectedTeamId)
            async let guestsTask = teamService.fetchTeamGuests(teamId: selectedTeamId)

            let team = try await teamTask
            let guests = (try? await guestsTask) ?? []
            selectedTeam = team.withGuests(guests)

            if let index = teams.firstIndex(where: { $0.id == selectedTeamId }),
               let selectedTeam {
                teams[index] = selectedTeam
            }
            errorMessage = nil
        } catch {
            if let cached = teams.first(where: { $0.id == selectedTeamId }) {
                let guests = (try? await teamService.fetchTeamGuests(teamId: selectedTeamId)) ?? []
                selectedTeam = cached.withGuests(guests)
                errorMessage = nil
            } else {
                selectedTeam = nil
                errorMessage = error.localizedDescription
            }
        }

        clearSectionLoadErrors()
        await loadSeasonsForSelectedTeam()

        async let statsTask: Void = loadTeamStats()
        async let invitationsTask: Void = loadTeamInvitations()
        _ = await (statsTask, invitationsTask)
        statsLoadedForTeamId = selectedTeamId

        if rankingsLoadedForTeamId != selectedTeamId {
            teamRankings = nil
        }
        if compositionsLoadedForTeamId != selectedTeamId {
            compositions = []
        }
    }

    func clearSectionLoadErrors() {
        compositionsLoadError = nil
        invitationsLoadError = nil
        statsLoadError = nil
        rankingsLoadError = nil
    }

    func loadSeasonsForSelectedTeam() async {
        guard !selectedTeamId.isEmpty else {
            availableSeasons = []
            seasonsTeamId = nil
            return
        }

        guard seasonsTeamId != selectedTeamId else { return }

        let seasons = await statsService.fetchAvailableSeasons()
        if seasons.isEmpty {
            availableSeasons = [SeasonFormatter.currentSeason()]
        } else {
            availableSeasons = seasons
        }
        selectedStatsSeason = availableSeasons.first ?? ""
        selectedRankingSeason = availableSeasons.first ?? ""
        seasonsTeamId = selectedTeamId
    }

    func loadCompositions() async {
        guard !selectedTeamId.isEmpty else {
            compositions = []
            compositionsLoadError = nil
            return
        }

        do {
            compositions = try await compositionService.fetchTeamCompositions(teamId: selectedTeamId)
            compositionsLoadError = nil
        } catch {
            compositions = []
            compositionsLoadError = error.localizedDescription
        }
    }

    func loadTeamStats() async {
        guard !selectedTeamId.isEmpty, !selectedStatsSeason.isEmpty else {
            teamSeasonStats = nil
            statsLoadError = nil
            return
        }

        isLoadingStats = true
        defer { isLoadingStats = false }

        do {
            if var stats = try await statsService.fetchTeamSeasonStats(
                teamId: selectedTeamId,
                season: selectedStatsSeason
            ) {
                if let team = selectedTeam {
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

    func loadTeamRankings() async {
        guard !selectedTeamId.isEmpty, !selectedRankingSeason.isEmpty else {
            teamRankings = nil
            rankingsLoadError = nil
            return
        }

        isLoadingRankings = true
        defer { isLoadingRankings = false }

        do {
            teamRankings = try await statsService.fetchTeamSeasonRankings(
                teamId: selectedTeamId,
                season: selectedRankingSeason
            )
            rankingsLoadError = nil
        } catch {
            teamRankings = nil
            rankingsLoadError = error.localizedDescription
        }
    }

    func loadTeamInvitations() async {
        guard canManageTeam, !selectedTeamId.isEmpty else {
            teamInvitations = []
            invitationsLoadError = nil
            return
        }

        isLoadingInvitations = true
        defer { isLoadingInvitations = false }

        do {
            teamInvitations = try await teamService.fetchTeamInvitations(teamId: selectedTeamId)
            invitationsLoadError = nil
        } catch {
            teamInvitations = []
            invitationsLoadError = error.localizedDescription
        }
    }

    func replaceTeam(_ team: SquadTeam) {
        if let index = teams.firstIndex(where: { $0.id == team.id }) {
            teams[index] = team
        }
        if selectedTeamId == team.id {
            selectedTeam = team
        }
    }
}
