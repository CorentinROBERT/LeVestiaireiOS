//
//  TeamViewModel+Preview.swift
//  LeVestaire
//

#if DEBUG
import Foundation

extension TeamViewModel {
    static func preview(
        role: TeamRole = .admin,
        includeSecondTeam: Bool = true
    ) -> TeamViewModel {
        let viewModel = TeamViewModel()
        let selectedTeam = TeamPreviewData.team(role: role)
        viewModel.applyPreviewState(
            teams: TeamPreviewData.teams(includeSecond: includeSecondTeam),
            selectedTeam: selectedTeam,
            compositions: TeamPreviewData.compositions,
            stats: TeamPreviewData.stats,
            rankings: TeamPreviewData.rankings,
            invitations: TeamPreviewData.invitations,
            seasons: TeamPreviewData.seasons
        )
        return viewModel
    }

    static func previewEmpty() -> TeamViewModel {
        let viewModel = TeamViewModel()
        viewModel.applyPreviewState(
            teams: [],
            selectedTeam: nil,
            compositions: [],
            stats: nil,
            rankings: nil,
            invitations: [],
            seasons: []
        )
        return viewModel
    }

    func applyPreviewState(
        teams: [SquadTeam],
        selectedTeam: SquadTeam?,
        compositions: [TeamComposition] = [],
        stats: TeamSeasonStatsPayload? = nil,
        rankings: TeamSeasonRankings? = nil,
        invitations: [TeamInvitation] = [],
        seasons: [String] = []
    ) {
        self.teams = teams
        self.selectedTeam = selectedTeam
        selectedTeamId = selectedTeam?.id ?? ""
        compositionsViewModel.compositions = compositions
        statsViewModel.teamSeasonStats = stats
        statsViewModel.teamRankings = rankings
        invitationsViewModel.teamInvitations = invitations
        statsViewModel.availableSeasons = seasons
        statsViewModel.selectedStatsSeason = seasons.first ?? TeamPreviewData.season
        statsViewModel.selectedRankingSeason = seasons.first ?? TeamPreviewData.season
        isLoading = false
        isRefreshingTeam = false
        statsViewModel.isLoadingStats = false
        statsViewModel.isLoadingRankings = false
        invitationsViewModel.isLoadingInvitations = false
        isSubmitting = false
    }
}
#endif
