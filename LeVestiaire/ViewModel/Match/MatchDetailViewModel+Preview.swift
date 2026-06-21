//
//  MatchDetailViewModel+Preview.swift
//  LeVestaire
//

#if DEBUG
import Foundation

extension MatchDetailViewModel {
    @MainActor
    static func preview(
        status: MatchStatus = .finished,
        composition: TeamComposition? = nil
    ) -> MatchDetailViewModel {
        let viewModel = MatchDetailViewModel(matchId: "preview-match")
        viewModel.applyPreviewState(
            match: MatchPreviewData.detail(
                status: status,
                composition: composition ?? TeamPreviewData.compositions.first
            ),
            canManageMatchTeam: true
        )
        return viewModel
    }
}
#endif
