//
//  MatchsViewModel+Preview.swift
//  LeVestaire
//

#if DEBUG
import Foundation

extension MatchsViewModel {
    static func preview(
        matches: [MatchItem] = MatchPreviewData.listingFlow,
        teams: [SquadTeam] = TeamPreviewData.teams(includeSecond: true),
        filters: MatchFilters = MatchFilters(),
        submittingAvailabilityMatchIds: Set<String> = []
    ) -> MatchsViewModel {
        let viewModel = MatchsViewModel()
        viewModel.applyPreviewState(
            matches: matches,
            teams: teams,
            filters: filters,
            submittingAvailabilityMatchIds: submittingAvailabilityMatchIds
        )
        return viewModel
    }

    static func previewEmpty() -> MatchsViewModel {
        preview(matches: [], teams: TeamPreviewData.teams(includeSecond: false))
    }

    static func previewFiltered() -> MatchsViewModel {
        preview(
            matches: MatchPreviewData.listingFlow.filter { $0.status == .draft || $0.status == .upcoming },
            filters: MatchFilters(
                statuses: [.draft, .upcoming],
                teamIds: [TeamPreviewData.team().id],
                fromDate: MatchPreviewData.daysFromNow(-1),
                toDate: MatchPreviewData.daysFromNow(30)
            )
        )
    }

    static func previewSubmittingAvailability() -> MatchsViewModel {
        preview(submittingAvailabilityMatchIds: ["preview-match-draft-pending"])
    }
}
#endif
