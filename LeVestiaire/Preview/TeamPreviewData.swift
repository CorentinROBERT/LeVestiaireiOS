//
//  TeamPreviewData.swift
//  LeVestaire
//

#if DEBUG
import Foundation

enum TeamPreviewData {
    static let season = "2025-2026"
    static let seasons = ["2025-2026", "2024-2025"]

    static let members: [TeamMember] = [
        TeamMember(
            id: "member-1",
            userId: "user-1",
            firstName: "Lucas",
            lastName: "Martin",
            role: .admin,
            jerseyNumber: 1
        ),
        TeamMember(
            id: "member-2",
            userId: "user-2",
            firstName: "Emma",
            lastName: "Bernard",
            role: .manager,
            jerseyNumber: 7
        ),
        TeamMember(
            id: "member-3",
            userId: "user-3",
            firstName: "Hugo",
            lastName: "Petit",
            role: .player,
            jerseyNumber: 10
        ),
        TeamMember(
            id: "member-4",
            userId: "user-4",
            firstName: "Léa",
            lastName: "Moreau",
            role: .player,
            jerseyNumber: 9
        ),
        TeamMember(
            id: "member-5",
            userId: "user-5",
            firstName: "Tom",
            lastName: "Durand",
            role: .player,
            jerseyNumber: 4
        ),
        TeamMember(
            id: "member-6",
            userId: "user-6",
            firstName: "Chloé",
            lastName: "Leroy",
            role: .player,
            jerseyNumber: 6
        ),
        TeamMember(
            id: "member-7",
            userId: "user-7",
            firstName: "Nathan",
            lastName: "Garcia",
            role: .player,
            jerseyNumber: 11
        )
    ]

    static func team(
        id: String = "team-1",
        name: String = "FC Squad Locker",
        role: TeamRole = .admin
    ) -> SquadTeam {
        SquadTeam(
            id: id,
            name: name,
            description: "Équipe de preview pour le terrain 7v7.",
            members: members,
            memberCount: members.count,
            currentUserRole: role,
            invitationCode: "SLCK25",
            sport: "football",
            league: "ligue-amateur"
        )
    }

    static func teams(includeSecond: Bool = true) -> [SquadTeam] {
        var result = [team()]
        if includeSecond {
            result.append(
                team(
                    id: "team-2",
                    name: "Les Renards",
                    role: .player
                )
            )
        }
        return result
    }

    static let fieldAssignments: [String: String] = [
        "GK": "user-1",
        "D1": "user-5",
        "D2": "user-6",
        "D3": "user-2",
        "M1": "user-3",
        "M2": "user-7",
        "A1": "user-4"
    ]

    static let compositions: [TeamComposition] = [
        TeamComposition(
            id: "composition-1",
            name: "Titulaires",
            formation: FormationCatalog.defaultFormationKey,
            tacticalNotes: "Pressing haut dès la perte de balle.",
            teamId: "team-1",
            captainId: "user-3",
            starters: [
                CompositionAssignment(position: "GK", memberId: "user-1", firstName: "Lucas", lastName: "Martin"),
                CompositionAssignment(position: "D1", memberId: "user-5", firstName: "Tom", lastName: "Durand"),
                CompositionAssignment(position: "D2", memberId: "user-6", firstName: "Chloé", lastName: "Leroy"),
                CompositionAssignment(position: "D3", memberId: "user-2", firstName: "Emma", lastName: "Bernard"),
                CompositionAssignment(position: "M1", memberId: "user-3", firstName: "Hugo", lastName: "Petit"),
                CompositionAssignment(position: "M2", memberId: "user-7", firstName: "Nathan", lastName: "Garcia"),
                CompositionAssignment(position: "A1", memberId: "user-4", firstName: "Léa", lastName: "Moreau")
            ],
            substitutes: [
                CompositionAssignment(
                    position: "SUB",
                    memberId: "user-2",
                    firstName: "Emma",
                    lastName: "Bernard",
                    isStarter: false
                )
            ],
            alternatives: [
                CompositionAlternative(
                    id: "alt-1",
                    name: "Variante attaque",
                    formation: "1-2-3-1"
                ),
                CompositionAlternative(
                    id: "alt-2",
                    name: "Variante défense",
                    formation: "1-3-1-2"
                )
            ]
        ),
        TeamComposition(
            id: "composition-2",
            name: "Match amical",
            formation: "1-2-3-1",
            teamId: "team-1"
        )
    ]

    static let stats = TeamSeasonStatsPayload(
        teamId: "team-1",
        season: season,
        totals: TeamSeasonStatsTotals(
            goals: 28,
            assists: 19,
            yellowCards: 4,
            redCards: 1,
            cleanSheets: 3,
            manOfTheMatchCount: 3,
            minutesPlayed: 840
        ),
        players: [
            TeamPlayerSeasonStats(
                id: "user-3",
                firstName: "Hugo",
                lastName: "Petit",
                goals: 9,
                assists: 5,
                minutesPlayed: 720,
                matchesPlayed: 11
            ),
            TeamPlayerSeasonStats(
                id: "user-4",
                firstName: "Léa",
                lastName: "Moreau",
                goals: 7,
                assists: 4,
                minutesPlayed: 660,
                matchesPlayed: 10
            ),
            TeamPlayerSeasonStats(
                id: "user-2",
                firstName: "Emma",
                lastName: "Bernard",
                goals: 5,
                assists: 6,
                yellowCards: 2,
                minutesPlayed: 600,
                matchesPlayed: 12
            ),
            TeamPlayerSeasonStats(
                id: "user-1",
                firstName: "Lucas",
                lastName: "Martin",
                goals: 0,
                assists: 0,
                saves: 18,
                minutesPlayed: 1080,
                matchesPlayed: 12
            )
        ]
    )

    static let rankings = TeamSeasonRankings(
        scorers: [
            RankingPlayerEntry(id: "user-3", firstName: "Hugo", lastName: "Petit", goals: 9),
            RankingPlayerEntry(id: "user-4", firstName: "Léa", lastName: "Moreau", goals: 7)
        ],
        assisters: [
            RankingPlayerEntry(id: "user-2", firstName: "Emma", lastName: "Bernard", assists: 6),
            RankingPlayerEntry(id: "user-3", firstName: "Hugo", lastName: "Petit", assists: 5)
        ],
        general: [
            RankingPlayerEntry(id: "user-3", firstName: "Hugo", lastName: "Petit", points: 24),
            RankingPlayerEntry(id: "user-4", firstName: "Léa", lastName: "Moreau", points: 18)
        ]
    )

    static let invitations: [TeamInvitation] = [
        TeamInvitation(
            id: "inv-1",
            email: "nouveau@exemple.com",
            firstName: "Alex",
            lastName: "Durand",
            status: .pending
        ),
        TeamInvitation(
            id: "inv-2",
            email: "joueur@exemple.com",
            firstName: "Sam",
            lastName: "Martin",
            status: .accepted
        )
    ]

    static let insights = TeamSeasonInsightsPayload(
        teamId: "team-1",
        season: season,
        form: TeamFormInsights(
            results: [.win, .win, .draw, .loss, .win],
            points: 10,
            goalsFor: 12,
            goalsAgainst: 8
        ),
        streak: TeamStreakInsights(type: .unbeaten, count: 2),
        seasonSummary: TeamSeasonSummaryInsights(
            played: 12,
            wins: 7,
            draws: 2,
            losses: 3,
            goalsFor: 28,
            goalsAgainst: 16,
            points: 23,
            cleanSheets: 3
        ),
        playerOfMoment: TeamPlayerOfMomentInsights(
            player: TeamInsightsPlayerRef(id: "user-3", firstName: "Hugo", lastName: "Petit"),
            goals: 4,
            assists: 2,
            scope: .recent
        ),
        availability: TeamAvailabilityInsights(
            averageResponseRate: 0.82,
            nextMatchResponseRate: 0.65
        ),
        nextMatch: TeamNextMatchInsights(
            match: TeamInsightsMatchPreview(
                id: "preview-next-match",
                title: "vs Olympique Nord",
                opponentTeam: "Olympique Nord",
                date: Calendar.current.date(byAdding: .day, value: 3, to: Date()),
                startTime: "20:30",
                status: .upcoming
            ),
            availability: TeamNextMatchAvailabilitySummary(
                available: 9,
                absent: 2,
                unknown: 3
            )
        )
    )

    static let duos = TeamSeasonDuosPayload(
        teamId: "team-1",
        season: season,
        duos: [
            TeamSeasonDuoEntry(
                pairKey: "user-3|user-4",
                playerA: TeamInsightsPlayerRef(id: "user-3", firstName: "Hugo", lastName: "Petit"),
                playerB: TeamInsightsPlayerRef(id: "user-4", firstName: "Léa", lastName: "Moreau"),
                goalsTogether: 5,
                totalCombos: 4
            ),
            TeamSeasonDuoEntry(
                pairKey: "user-2|user-3",
                playerA: TeamInsightsPlayerRef(id: "user-2", firstName: "Emma", lastName: "Bernard"),
                playerB: TeamInsightsPlayerRef(id: "user-3", firstName: "Hugo", lastName: "Petit"),
                goalsTogether: 3,
                totalCombos: 3
            )
        ]
    )
}
#endif
