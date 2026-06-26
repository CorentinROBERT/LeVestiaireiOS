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

    func selectTeamFromNotification(id: String) async {
        if !teams.contains(where: { $0.id == id }) {
            await loadInitialData()
        }

        guard teams.contains(where: { $0.id == id }) else { return }

        selectedTeamId = id
        await onTeamSelectionChanged()
    }

    func loadTabContentIfNeeded(_ tab: TeamContentTab, force: Bool = false) async {
        guard !selectedTeamId.isEmpty else { return }

        switch tab {
        case .roster:
            break
        case .stats, .rankings:
            await statsViewModel.loadIfNeeded(tab, force: force)
        case .compositions:
            await compositionsViewModel.loadIfNeeded(force: force)
        }
    }

    func retryTeamDetail() async {
        await refreshSelectedTeamContent()
    }

    func invalidateLazyTabLoads() {
        statsViewModel.invalidateLazyLoads()
        compositionsViewModel.invalidateLazyLoads()
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
            statsViewModel.resetCache()
            invitationsViewModel.resetCache()
            joinRequestsViewModel.resetCache()
            compositionsViewModel.resetCache()
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
        await statsViewModel.loadSeasonsIfNeeded()

        async let invitationsTask: Void = invitationsViewModel.loadIfNeeded()
        async let joinRequestsTask: Void = joinRequestsViewModel.loadIfNeeded()
        _ = await (invitationsTask, joinRequestsTask)

        statsViewModel.prepareForTeamChange()
        compositionsViewModel.prepareForTeamChange()
    }

    func clearSectionLoadErrors() {
        statsViewModel.clearLoadErrors()
        invitationsViewModel.clearLoadErrors()
        joinRequestsViewModel.clearLoadErrors()
        compositionsViewModel.clearLoadErrors()
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
