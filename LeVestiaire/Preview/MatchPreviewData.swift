//
//  MatchPreviewData.swift
//  LeVestaire
//

#if DEBUG
import Foundation

enum MatchPreviewData {
    static let playerRespondCapabilities = MatchCapabilities(
        canRespond: true,
        canManageAvailability: false,
        canManageComposition: false,
        canPublish: false,
        canStartMatch: false,
        canManageEvents: false,
        canUpdateScore: false,
        canFinishMatch: false
    )

    static let staffPrepareCapabilities = MatchCapabilities(
        canRespond: false,
        canManageAvailability: true,
        canManageComposition: true,
        canPublish: true,
        canStartMatch: false,
        canManageEvents: false,
        canUpdateScore: false,
        canFinishMatch: false
    )

    static func daysFromNow(_ days: Int, hour: Int = 20, minute: Int = 0) -> Date {
        var components = Calendar.current.dateComponents([.year, .month, .day], from: Date())
        components.day = (components.day ?? 0) + days
        components.hour = hour
        components.minute = minute
        return Calendar.current.date(from: components) ?? Date()
    }

    static func listingItem(
        id: String,
        title: String,
        status: MatchStatus,
        opponentTeam: String,
        date: Date,
        startTime: String = "20:00",
        location: String = "Stade municipal",
        myAvailabilityStatus: MatchAvailabilityStatus? = nil,
        availabilitySummary: AvailabilitySummary? = nil,
        capabilities: MatchCapabilities = playerRespondCapabilities,
        homeScore: Int? = nil,
        awayScore: Int? = nil,
        preparationPhase: MatchPreparationPhase? = nil
    ) -> MatchItem {
        let team = TeamPreviewData.team()
        return MatchItem(
            id: id,
            title: title,
            status: status,
            preparationPhase: preparationPhase,
            myAvailabilityStatus: myAvailabilityStatus,
            availabilitySummary: availabilitySummary,
            capabilities: capabilities,
            opponentTeam: opponentTeam,
            location: location,
            homeTeamName: team.name,
            teamId: team.id,
            date: date,
            startTime: startTime,
            homeScore: homeScore,
            awayScore: awayScore
        )
    }

    /// Scénarios variés pour le listing : préparation, dispo joueur, suivi staff, à venir, en cours, terminé.
    static var listingFlow: [MatchItem] {
        [
            listingItem(
                id: "preview-match-draft-pending",
                title: "vs FC Rivaux",
                status: .draft,
                opponentTeam: "FC Rivaux",
                date: daysFromNow(5),
                startTime: "20:30",
                location: "Complexe Jean Bouin",
                myAvailabilityStatus: nil,
                preparationPhase: .collectingAvailability
            ),
            listingItem(
                id: "preview-match-draft-responded",
                title: "vs Olympique Nord",
                status: .draft,
                opponentTeam: "Olympique Nord",
                date: daysFromNow(12),
                myAvailabilityStatus: .available,
                preparationPhase: .collectingAvailability
            ),
            listingItem(
                id: "preview-match-draft-staff",
                title: "vs AS Montclair",
                status: .draft,
                opponentTeam: "AS Montclair",
                date: daysFromNow(18),
                location: "Stade des Cèdres",
                availabilitySummary: AvailabilitySummary(
                    respondedCount: 9,
                    presentCount: 7,
                    totalEligible: 14,
                    totalMembers: 12,
                    totalGuests: 2,
                    absentCount: 2,
                    unknownCount: 5,
                    pendingCount: 5
                ),
                capabilities: staffPrepareCapabilities,
                preparationPhase: .buildingComposition
            ),
            listingItem(
                id: "preview-match-upcoming",
                title: "vs Union Sportive",
                status: .upcoming,
                opponentTeam: "Union Sportive",
                date: daysFromNow(2),
                startTime: "18:00",
                capabilities: .empty
            ),
            listingItem(
                id: "preview-match-ongoing",
                title: "vs Stade Lorrain",
                status: .ongoing,
                opponentTeam: "Stade Lorrain",
                date: Date(),
                startTime: "15:00",
                capabilities: MatchCapabilities(
                    canRespond: false,
                    canManageAvailability: false,
                    canManageComposition: false,
                    canPublish: false,
                    canStartMatch: false,
                    canManageEvents: true,
                    canUpdateScore: true,
                    canFinishMatch: true
                ),
                homeScore: 1,
                awayScore: 0
            ),
            listingItem(
                id: "preview-match-finished",
                title: "vs Teuteu FC",
                status: .finished,
                opponentTeam: "Teuteu FC",
                date: daysFromNow(-7),
                startTime: "20:00",
                capabilities: .empty,
                homeScore: 3,
                awayScore: 1
            )
        ]
    }

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
