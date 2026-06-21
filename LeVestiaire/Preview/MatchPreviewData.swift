//
//  MatchPreviewData.swift
//  LeVestaire
//

#if DEBUG
import Foundation

enum MatchPreviewData {
    @MainActor
    static func detail(
        id: String = "preview-match",
        status: MatchStatus = .finished,
        composition: TeamComposition? = nil
    ) -> MatchDetail {
        MatchDetail(
            id: id,
            title: "FC Squad Locker vs Rival FC",
            status: status,
            statusLabel: nil,
            preparationPhase: nil,
            isPreparationLocked: false,
            isCompositionLocked: false,
            canPublish: false,
            publishBlockers: [],
            myAvailabilityStatus: .available,
            availabilitySummary: nil,
            capabilities: MatchCapabilities(
                canRespond: true,
                canManageAvailability: true,
                canManageComposition: true,
                canPublish: false,
                canStartMatch: status == .upcoming,
                canManageEvents: status == .ongoing || status == .finished,
                canUpdateScore: status == .ongoing || status == .finished,
                canFinishMatch: status == .ongoing
            ),
            opponentTeam: "Rival FC",
            location: "Stade Municipal",
            homeTeamName: TeamPreviewData.team().name,
            teamId: TeamPreviewData.team().id,
            date: Date(),
            startTime: "20:00",
            homeScore: status == .upcoming ? nil : 2,
            awayScore: status == .upcoming ? nil : 1,
            composition: composition ?? TeamPreviewData.compositions.first
        )
    }
}
#endif
