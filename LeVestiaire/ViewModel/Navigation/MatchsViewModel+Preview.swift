//
//  MatchsViewModel+Preview.swift
//  LeVestaire
//

#if DEBUG
import Foundation

@MainActor
extension MatchsViewModel {
    static func preview() -> MatchsViewModel {
        preview(
            matches: MatchPreviewData.listingFlow,
            teams: TeamPreviewData.teams(includeSecond: true)
        )
    }

    static func preview(
        matches: [MatchItem],
        teams: [SquadTeam],
        filters: MatchFilters? = nil,
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
            teams: TeamPreviewData.teams(includeSecond: true),
            filters: MatchFilters(
                statuses: [.draft, .upcoming],
                teamIds: [TeamPreviewData.team().id],
                fromDate: MatchPreviewData.daysFromNow(-1),
                toDate: MatchPreviewData.daysFromNow(30)
            )
        )
    }

    static func previewSubmittingAvailability() -> MatchsViewModel {
        preview(
            matches: MatchPreviewData.listingFlow,
            teams: TeamPreviewData.teams(includeSecond: true),
            submittingAvailabilityMatchIds: ["preview-match-draft-pending"]
        )
    }
}
#endif
