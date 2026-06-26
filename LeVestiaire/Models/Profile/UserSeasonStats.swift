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
    let injuries: Int
    let shlagCount: Int
    let manOfTheMatchCount: Int
    let otherCount: Int
    let topConnection: String?

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
            || injuries > 0
            || shlagCount > 0
            || manOfTheMatchCount > 0
            || otherCount > 0
            || !(topConnection?.isEmpty ?? true)
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
        substitutionsOut: Int = 0,
        injuries: Int = 0,
        shlagCount: Int = 0,
        manOfTheMatchCount: Int = 0,
        otherCount: Int = 0,
        topConnection: String? = nil
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
        self.injuries = injuries
        self.shlagCount = shlagCount
        self.manOfTheMatchCount = manOfTheMatchCount
        self.otherCount = otherCount
        self.topConnection = topConnection
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
        injuries = Self.decodeInt(from: container, forKey: .injuries)
        shlagCount = Self.decodeInt(from: container, forKey: .shlagCount)
        manOfTheMatchCount = Self.decodeInt(from: container, forKey: .manOfTheMatchCount)
        otherCount = Self.decodeInt(from: container, forKey: .otherCount)
        topConnection = Self.decodeTopConnection(from: container)
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
        case injuries
        case shlagCount
        case manOfTheMatchCount
        case otherCount
        case topConnection
    }

    private struct TopConnectionUser: Decodable {
        let firstName: String?
        let lastName: String?
    }

    private static func decodeTopConnection(
        from container: KeyedDecodingContainer<CodingKeys>
    ) -> String? {
        if let value = try? container.decodeIfPresent(String.self, forKey: .topConnection),
           !value.isEmpty {
            return value
        }

        if let user = try? container.decodeIfPresent(TopConnectionUser.self, forKey: .topConnection) {
            let parts = [user.firstName, user.lastName]
                .compactMap { $0 }
                .filter { !$0.isEmpty }
            if !parts.isEmpty {
                return parts.joined(separator: " ")
            }
        }

        return nil
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
    static func currentSeason(referenceDate: Date = Date()) -> String {
        let calendar = Calendar.current
        let year = calendar.component(.year, from: referenceDate)
        let month = calendar.component(.month, from: referenceDate)

        if month >= 8 {
            return "\(year)-\(year + 1)"
        }

        return "\(year - 1)-\(year)"
    }

    /// Saison sportive immédiatement après (ex. 2025-2026 → 2026-2027).
    static func nextSeason(after season: String) -> String? {
        guard let (startYear, endYear) = parseSeasonYears(season) else { return nil }
        return "\(startYear + 1)-\(endYear + 1)"
    }

    /// Fusionne les saisons renvoyées par l'API avec la saison courante et la suivante
    /// pour permettre la planification avant qu'il y ait des matchs ou des stats.
    static func resolvedAvailableSeasons(
        apiSeasons: [String],
        referenceDate: Date = Date()
    ) -> [String] {
        var seasons = Set(apiSeasons)
        let current = currentSeason(referenceDate: referenceDate)
        seasons.insert(current)
        if let next = nextSeason(after: current) {
            seasons.insert(next)
        }
        return seasons.sorted()
    }

    /// Saison sélectionnée par défaut : courante si présente, sinon la plus récente.
    static func defaultSelection(
        from seasons: [String],
        referenceDate: Date = Date()
    ) -> String {
        let current = currentSeason(referenceDate: referenceDate)
        if seasons.contains(current) {
            return current
        }
        return seasons.last ?? current
    }

    /// Libellé compact pour les pickers (ex. 2025-2026 → 25-26).
    static func shortLabel(for season: String) -> String {
        guard let (startYear, endYear) = parseSeasonYears(season) else { return season }
        return String(format: "%02d-%02d", startYear % 100, endYear % 100)
    }

    /// Libellé complet (ex. 2025-2026).
    static func fullLabel(for season: String) -> String {
        guard let (startYear, endYear) = parseSeasonYears(season) else { return season }
        return "\(startYear)-\(endYear)"
    }

    private static func parseSeasonYears(_ season: String) -> (Int, Int)? {
        let parts = season.split(separator: "-", omittingEmptySubsequences: false)
        guard parts.count == 2,
              let startYear = Int(parts[0]),
              let endYear = Int(parts[1]) else {
            return nil
        }
        return (startYear, endYear)
    }
}
