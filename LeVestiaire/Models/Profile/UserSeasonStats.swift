//
//  UserSeasonStats.swift
//  LeVestaire
//
//  Created by Corentin Robert on 16/06/2026.
//

import Foundation

struct UserSeasonStats: Decodable, Equatable {
    let season: String?
    let matchesPlayed: Int
    let goals: Int
    let assists: Int
    let ownGoals: Int
    let yellowCards: Int
    let redCards: Int
    let shotsOnTarget: Int
    let saves: Int
    let minutesPlayed: Int
    let substitutionsIn: Int
    let substitutionsOut: Int

    var hasAnyValue: Bool {
        matchesPlayed > 0
            || goals > 0
            || assists > 0
            || ownGoals > 0
            || yellowCards > 0
            || redCards > 0
            || shotsOnTarget > 0
            || saves > 0
            || minutesPlayed > 0
            || substitutionsIn > 0
            || substitutionsOut > 0
    }

    init(
        season: String? = nil,
        matchesPlayed: Int = 0,
        goals: Int = 0,
        assists: Int = 0,
        ownGoals: Int = 0,
        yellowCards: Int = 0,
        redCards: Int = 0,
        shotsOnTarget: Int = 0,
        saves: Int = 0,
        minutesPlayed: Int = 0,
        substitutionsIn: Int = 0,
        substitutionsOut: Int = 0
    ) {
        self.season = season
        self.matchesPlayed = matchesPlayed
        self.goals = goals
        self.assists = assists
        self.ownGoals = ownGoals
        self.yellowCards = yellowCards
        self.redCards = redCards
        self.shotsOnTarget = shotsOnTarget
        self.saves = saves
        self.minutesPlayed = minutesPlayed
        self.substitutionsIn = substitutionsIn
        self.substitutionsOut = substitutionsOut
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        season = try container.decodeIfPresent(String.self, forKey: .season)
        matchesPlayed = Self.decodeInt(from: container, forKey: .matchesPlayed)
        goals = Self.decodeInt(from: container, forKey: .goals)
        assists = Self.decodeInt(from: container, forKey: .assists)
        ownGoals = Self.decodeInt(from: container, forKey: .ownGoals)
        yellowCards = Self.decodeInt(from: container, forKey: .yellowCards)
        redCards = Self.decodeInt(from: container, forKey: .redCards)
        shotsOnTarget = Self.decodeInt(from: container, forKey: .shotsOnTarget)
        saves = Self.decodeInt(from: container, forKey: .saves)
        minutesPlayed = Self.decodeInt(from: container, forKey: .minutesPlayed)
        substitutionsIn = Self.decodeInt(from: container, forKey: .substitutionsIn)
        substitutionsOut = Self.decodeInt(from: container, forKey: .substitutionsOut)
    }

    private enum CodingKeys: String, CodingKey {
        case season
        case matchesPlayed
        case goals
        case assists
        case ownGoals
        case yellowCards
        case redCards
        case shotsOnTarget
        case saves
        case minutesPlayed
        case substitutionsIn
        case substitutionsOut
    }

    private static func decodeInt<K: CodingKey>(
        from container: KeyedDecodingContainer<K>,
        forKey key: K
    ) -> Int {
        if let value = try? container.decodeIfPresent(Int.self, forKey: key) {
            return value
        }
        if let value = try? container.decodeIfPresent(Double.self, forKey: key) {
            return Int(value)
        }
        if let value = try? container.decodeIfPresent(String.self, forKey: key),
           let intValue = Int(value) {
            return intValue
        }
        return 0
    }
}

struct AvailableSeasonsResponse: Decodable, Equatable {
    let success: Bool?
    let data: AvailableSeasonsData?

    var seasons: [String] {
        if let seasons = data?.seasons, !seasons.isEmpty {
            return seasons
        }
        if let seasons = data?.available, !seasons.isEmpty {
            return seasons
        }
        return []
    }
}

struct AvailableSeasonsData: Decodable, Equatable {
    let seasons: [String]?
    let available: [String]?
}

enum SeasonFormatter {
    static func shortLabel(for season: String) -> String {
        let parts = season.split(separator: "-", omittingEmptySubsequences: false)
        guard parts.count == 2 else { return season }

        let start = parts[0]
        let end = parts[1]
        let shortStart = start.count > 2 ? String(start.suffix(2)) : String(start)
        return "\(shortStart)-\(end)"
    }
}
