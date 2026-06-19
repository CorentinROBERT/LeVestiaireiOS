//
//  TeamSeasonStatsModels.swift
//  LeVestaire
//

import Foundation

struct TeamSeasonStatsPayload: Decodable, Equatable {
    let teamId: String?
    let season: String?
    let totals: TeamSeasonStatsTotals
    let players: [TeamPlayerSeasonStats]

    init(
        teamId: String? = nil,
        season: String? = nil,
        totals: TeamSeasonStatsTotals,
        players: [TeamPlayerSeasonStats] = []
    ) {
        self.teamId = teamId
        self.season = season
        self.totals = totals
        self.players = players
    }

    var sortedPlayers: [TeamPlayerSeasonStats] {
        players.sorted { lhs, rhs in
            if lhs.goals != rhs.goals { return lhs.goals > rhs.goals }
            if lhs.assists != rhs.assists { return lhs.assists > rhs.assists }
            if lhs.matchesPlayed != rhs.matchesPlayed { return lhs.matchesPlayed > rhs.matchesPlayed }
            return lhs.displayName.localizedCaseInsensitiveCompare(rhs.displayName) == .orderedAscending
        }
    }

    var totalMatchesPlayed: Int {
        players.reduce(0) { $0 + $1.matchesPlayed }
    }

    var hasContent: Bool {
        totals.hasAnyValue || !players.isEmpty
    }
}

struct TeamSeasonStatsTotals: Decodable, Equatable {
    let goals: Int
    let ownGoals: Int
    let assists: Int
    let yellowCards: Int
    let redCards: Int
    let substitutionsIn: Int
    let substitutionsOut: Int
    let shotsOnTarget: Int
    let saves: Int
    let injuries: Int
    let shlagCount: Int
    let manOfTheMatchCount: Int
    let otherCount: Int
    let minutesPlayed: Int
    let topConnection: String?

    var hasAnyValue: Bool {
        goals > 0
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
        goals: Int = 0,
        ownGoals: Int = 0,
        assists: Int = 0,
        yellowCards: Int = 0,
        redCards: Int = 0,
        substitutionsIn: Int = 0,
        substitutionsOut: Int = 0,
        shotsOnTarget: Int = 0,
        saves: Int = 0,
        injuries: Int = 0,
        shlagCount: Int = 0,
        manOfTheMatchCount: Int = 0,
        otherCount: Int = 0,
        minutesPlayed: Int = 0,
        topConnection: String? = nil
    ) {
        self.goals = goals
        self.ownGoals = ownGoals
        self.assists = assists
        self.yellowCards = yellowCards
        self.redCards = redCards
        self.substitutionsIn = substitutionsIn
        self.substitutionsOut = substitutionsOut
        self.shotsOnTarget = shotsOnTarget
        self.saves = saves
        self.injuries = injuries
        self.shlagCount = shlagCount
        self.manOfTheMatchCount = manOfTheMatchCount
        self.otherCount = otherCount
        self.minutesPlayed = minutesPlayed
        self.topConnection = topConnection
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        goals = SeasonStatsDecoding.int(from: container, forKey: .goals)
        ownGoals = SeasonStatsDecoding.int(from: container, forKey: .ownGoals)
        assists = SeasonStatsDecoding.int(from: container, forKey: .assists)
        yellowCards = SeasonStatsDecoding.int(from: container, forKey: .yellowCards)
        redCards = SeasonStatsDecoding.int(from: container, forKey: .redCards)
        substitutionsIn = SeasonStatsDecoding.int(from: container, forKey: .substitutionsIn)
        substitutionsOut = SeasonStatsDecoding.int(from: container, forKey: .substitutionsOut)
        shotsOnTarget = SeasonStatsDecoding.int(from: container, forKey: .shotsOnTarget)
        saves = SeasonStatsDecoding.int(from: container, forKey: .saves)
        injuries = SeasonStatsDecoding.int(from: container, forKey: .injuries)
        shlagCount = SeasonStatsDecoding.int(from: container, forKey: .shlagCount)
        manOfTheMatchCount = SeasonStatsDecoding.int(from: container, forKey: .manOfTheMatchCount)
        otherCount = SeasonStatsDecoding.int(from: container, forKey: .otherCount)
        minutesPlayed = SeasonStatsDecoding.int(from: container, forKey: .minutesPlayed)
        topConnection = SeasonStatsDecoding.topConnection(from: container, forKey: .topConnection)
    }

    private enum CodingKeys: String, CodingKey {
        case goals
        case ownGoals
        case assists
        case yellowCards
        case redCards
        case substitutionsIn
        case substitutionsOut
        case shotsOnTarget
        case saves
        case injuries
        case shlagCount
        case manOfTheMatchCount
        case otherCount
        case minutesPlayed
        case topConnection
    }
}

struct TeamPlayerSeasonStats: Identifiable, Decodable, Equatable {
    let id: String
    let firstName: String?
    let lastName: String?
    let goals: Int
    let ownGoals: Int
    let assists: Int
    let yellowCards: Int
    let redCards: Int
    let substitutionsIn: Int
    let substitutionsOut: Int
    let shotsOnTarget: Int
    let saves: Int
    let injuries: Int
    let shlagCount: Int
    let manOfTheMatchCount: Int
    let otherCount: Int
    let minutesPlayed: Int
    let topConnection: String?
    let matchesPlayed: Int

    var displayName: String {
        let parts = [firstName, lastName]
            .compactMap { $0?.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
        return parts.isEmpty ? L10n.text("user") : parts.joined(separator: " ")
    }

    var initials: String {
        let first = firstName?.first.map(String.init) ?? ""
        let last = lastName?.first.map(String.init) ?? ""
        let value = (first + last).uppercased()
        return value.isEmpty ? "?" : value
    }

    var hasAnyValue: Bool {
        matchesPlayed > 0
            || goals > 0
            || assists > 0
            || minutesPlayed > 0
            || yellowCards > 0
            || redCards > 0
    }

    init(
        id: String,
        firstName: String? = nil,
        lastName: String? = nil,
        goals: Int = 0,
        ownGoals: Int = 0,
        assists: Int = 0,
        yellowCards: Int = 0,
        redCards: Int = 0,
        substitutionsIn: Int = 0,
        substitutionsOut: Int = 0,
        shotsOnTarget: Int = 0,
        saves: Int = 0,
        injuries: Int = 0,
        shlagCount: Int = 0,
        manOfTheMatchCount: Int = 0,
        otherCount: Int = 0,
        minutesPlayed: Int = 0,
        topConnection: String? = nil,
        matchesPlayed: Int = 0
    ) {
        self.id = id
        self.firstName = firstName
        self.lastName = lastName
        self.goals = goals
        self.ownGoals = ownGoals
        self.assists = assists
        self.yellowCards = yellowCards
        self.redCards = redCards
        self.substitutionsIn = substitutionsIn
        self.substitutionsOut = substitutionsOut
        self.shotsOnTarget = shotsOnTarget
        self.saves = saves
        self.injuries = injuries
        self.shlagCount = shlagCount
        self.manOfTheMatchCount = manOfTheMatchCount
        self.otherCount = otherCount
        self.minutesPlayed = minutesPlayed
        self.topConnection = topConnection
        self.matchesPlayed = matchesPlayed
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let user = try container.decodeIfPresent(User.self, forKey: .user)
        id = user?.id ?? UUID().uuidString
        firstName = user?.firstName
        lastName = user?.lastName
        goals = SeasonStatsDecoding.int(from: container, forKey: .goals)
        ownGoals = SeasonStatsDecoding.int(from: container, forKey: .ownGoals)
        assists = SeasonStatsDecoding.int(from: container, forKey: .assists)
        yellowCards = SeasonStatsDecoding.int(from: container, forKey: .yellowCards)
        redCards = SeasonStatsDecoding.int(from: container, forKey: .redCards)
        substitutionsIn = SeasonStatsDecoding.int(from: container, forKey: .substitutionsIn)
        substitutionsOut = SeasonStatsDecoding.int(from: container, forKey: .substitutionsOut)
        shotsOnTarget = SeasonStatsDecoding.int(from: container, forKey: .shotsOnTarget)
        saves = SeasonStatsDecoding.int(from: container, forKey: .saves)
        injuries = SeasonStatsDecoding.int(from: container, forKey: .injuries)
        shlagCount = SeasonStatsDecoding.int(from: container, forKey: .shlagCount)
        manOfTheMatchCount = SeasonStatsDecoding.int(from: container, forKey: .manOfTheMatchCount)
        otherCount = SeasonStatsDecoding.int(from: container, forKey: .otherCount)
        minutesPlayed = SeasonStatsDecoding.int(from: container, forKey: .minutesPlayed)
        topConnection = SeasonStatsDecoding.topConnection(from: container, forKey: .topConnection)
        matchesPlayed = SeasonStatsDecoding.int(from: container, forKey: .matchesPlayed)
    }

    private enum CodingKeys: String, CodingKey {
        case user
        case goals
        case ownGoals
        case assists
        case yellowCards
        case redCards
        case substitutionsIn
        case substitutionsOut
        case shotsOnTarget
        case saves
        case injuries
        case shlagCount
        case manOfTheMatchCount
        case otherCount
        case minutesPlayed
        case topConnection
        case matchesPlayed
    }

    private struct User: Decodable {
        let id: String
        let firstName: String?
        let lastName: String?

        private enum CodingKeys: String, CodingKey {
            case mongoId = "_id"
            case id
            case firstName
            case lastName
        }

        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            if let mongoId = try container.decodeIfPresent(String.self, forKey: .mongoId) {
                id = mongoId
            } else {
                id = try container.decode(String.self, forKey: .id)
            }
            firstName = try container.decodeIfPresent(String.self, forKey: .firstName)
            lastName = try container.decodeIfPresent(String.self, forKey: .lastName)
        }
    }
}

private enum SeasonStatsDecoding {
    static func int<K: CodingKey>(
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

    static func topConnection<K: CodingKey>(
        from container: KeyedDecodingContainer<K>,
        forKey key: K
    ) -> String? {
        if let value = try? container.decodeIfPresent(String.self, forKey: key),
           !value.isEmpty {
            return value
        }

        if let user = try? container.decodeIfPresent(TopConnectionUser.self, forKey: key) {
            let parts = [user.firstName, user.lastName]
                .compactMap { $0 }
                .filter { !$0.isEmpty }
            if !parts.isEmpty {
                return parts.joined(separator: " ")
            }
        }

        return nil
    }

    private struct TopConnectionUser: Decodable {
        let firstName: String?
        let lastName: String?
    }
}
