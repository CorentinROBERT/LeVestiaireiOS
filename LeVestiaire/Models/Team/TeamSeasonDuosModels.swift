//
//  TeamSeasonDuosModels.swift
//  LeVestaire
//

import Foundation

struct TeamSeasonDuosPayload: Decodable, Equatable {
    let teamId: String?
    let season: String?
    let duos: [TeamSeasonDuoEntry]

    init(
        teamId: String? = nil,
        season: String? = nil,
        duos: [TeamSeasonDuoEntry] = []
    ) {
        self.teamId = teamId
        self.season = season
        self.duos = duos
    }

    init(from decoder: Decoder) throws {
        if let container = try? decoder.container(keyedBy: CodingKeys.self) {
            teamId = try container.decodeIfPresent(String.self, forKey: .teamId)
            season = try container.decodeIfPresent(String.self, forKey: .season)
            duos = try container.decodeIfPresent([TeamSeasonDuoEntry].self, forKey: .duos) ?? []
            return
        }

        var unkeyed = try decoder.unkeyedContainer()
        var entries: [TeamSeasonDuoEntry] = []
        while !unkeyed.isAtEnd {
            entries.append(try unkeyed.decode(TeamSeasonDuoEntry.self))
        }
        teamId = nil
        season = nil
        duos = entries
    }

    var hasContent: Bool {
        !duos.isEmpty
    }

    private enum CodingKeys: String, CodingKey {
        case teamId
        case season
        case duos
    }
}

struct TeamSeasonDuoEntry: Decodable, Equatable, Identifiable {
    let pairKey: String
    let playerA: TeamInsightsPlayerRef
    let playerB: TeamInsightsPlayerRef
    let goalsTogether: Int
    let totalCombos: Int

    var id: String { pairKey }

    init(
        pairKey: String? = nil,
        playerA: TeamInsightsPlayerRef,
        playerB: TeamInsightsPlayerRef,
        goalsTogether: Int = 0,
        totalCombos: Int = 0
    ) {
        self.pairKey = pairKey ?? Self.makePairKey(playerA: playerA, playerB: playerB)
        self.playerA = playerA
        self.playerB = playerB
        self.goalsTogether = goalsTogether
        self.totalCombos = totalCombos
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        playerA = try container.decode(TeamInsightsPlayerRef.self, forKey: .playerA)
        playerB = try container.decode(TeamInsightsPlayerRef.self, forKey: .playerB)
        goalsTogether = SeasonStatsDecoding.int(from: container, forKey: .goalsTogether)
        totalCombos = SeasonStatsDecoding.int(from: container, forKey: .totalCombos)
        pairKey = try container.decodeIfPresent(String.self, forKey: .pairKey)
            ?? Self.makePairKey(playerA: playerA, playerB: playerB)
    }

    private static func makePairKey(playerA: TeamInsightsPlayerRef, playerB: TeamInsightsPlayerRef) -> String {
        [playerA.id, playerB.id].sorted().joined(separator: "|")
    }

    private enum CodingKeys: String, CodingKey {
        case pairKey
        case playerA
        case playerB
        case goalsTogether
        case totalCombos
    }
}
