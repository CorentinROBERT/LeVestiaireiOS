//
//  TeamSeasonInsightsModels.swift
//  LeVestaire
//

import Foundation

struct TeamSeasonInsightsPayload: Decodable, Equatable {
    let teamId: String?
    let season: String?
    let form: TeamFormInsights?
    let streak: TeamStreakInsights?
    let seasonSummary: TeamSeasonSummaryInsights?
    let playerOfMoment: TeamPlayerOfMomentInsights?
    let availability: TeamAvailabilityInsights?
    let nextMatch: TeamNextMatchInsights?

    init(
        teamId: String? = nil,
        season: String? = nil,
        form: TeamFormInsights? = nil,
        streak: TeamStreakInsights? = nil,
        seasonSummary: TeamSeasonSummaryInsights? = nil,
        playerOfMoment: TeamPlayerOfMomentInsights? = nil,
        availability: TeamAvailabilityInsights? = nil,
        nextMatch: TeamNextMatchInsights? = nil
    ) {
        self.teamId = teamId
        self.season = season
        self.form = form
        self.streak = streak
        self.seasonSummary = seasonSummary
        self.playerOfMoment = playerOfMoment
        self.availability = availability
        self.nextMatch = nextMatch
    }

    var hasContent: Bool {
        form?.hasContent == true
            || streak != nil
            || seasonSummary?.hasContent == true
            || playerOfMoment?.hasContent == true
            || availability?.hasContent == true
            || nextMatch?.hasContent == true
    }
}

struct TeamFormInsights: Decodable, Equatable {
    let results: [TeamMatchResult]
    let points: Int
    let goalsFor: Int
    let goalsAgainst: Int

    var hasContent: Bool {
        !results.isEmpty || points > 0 || goalsFor > 0 || goalsAgainst > 0
    }

    init(
        results: [TeamMatchResult] = [],
        points: Int = 0,
        goalsFor: Int = 0,
        goalsAgainst: Int = 0
    ) {
        self.results = results
        self.points = points
        self.goalsFor = goalsFor
        self.goalsAgainst = goalsAgainst
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        if let matchResults = try? container.decode([TeamFormMatchEntry].self, forKey: .matches) {
            results = matchResults.compactMap(\.result)
        } else if let rawResults = try? container.decode([String].self, forKey: .results) {
            results = rawResults.compactMap(TeamMatchResult.init(rawValue:))
        } else {
            results = []
        }

        points = SeasonStatsDecoding.int(from: container, forKey: .points) ?? 0
        goalsFor = SeasonStatsDecoding.int(from: container, forKey: .goalsFor) ?? 0
        goalsAgainst = SeasonStatsDecoding.int(from: container, forKey: .goalsAgainst) ?? 0
    }

    private enum CodingKeys: String, CodingKey {
        case matches
        case results
        case points
        case goalsFor
        case goalsAgainst
    }
}

struct TeamFormMatchEntry: Decodable, Equatable {
    let matchId: String?
    let opponentTeam: String?
    let result: TeamMatchResult?

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        matchId = try container.decodeIfPresent(String.self, forKey: .matchId)
            ?? container.decodeIfPresent(String.self, forKey: .id)
        opponentTeam = try container.decodeIfPresent(String.self, forKey: .opponentTeam)
        if let raw = try container.decodeIfPresent(String.self, forKey: .result) {
            result = TeamMatchResult(rawValue: raw)
        } else {
            result = nil
        }
    }

    private enum CodingKeys: String, CodingKey {
        case matchId
        case id
        case opponentTeam
        case result
    }
}

enum TeamMatchResult: String, Decodable, Equatable, CaseIterable {
    case win
    case draw
    case loss

    init?(rawValue: String) {
        switch rawValue.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() {
        case "w", "win", "v", "victory", "victoire":
            self = .win
        case "d", "draw", "n", "nul":
            self = .draw
        case "l", "loss", "defeat", "défaite", "defaite":
            self = .loss
        default:
            return nil
        }
    }

    var shortLabel: String {
        switch self {
        case .win:
            return "V"
        case .draw:
            return "N"
        case .loss:
            return "D"
        }
    }
}

enum TeamStreakType: String, Decodable, Equatable {
    case win
    case loss
    case unbeaten
    case winless

    init?(rawValue: String) {
        switch rawValue.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() {
        case "win", "wins", "victory", "victoire":
            self = .win
        case "loss", "losses", "defeat", "défaite", "defaite":
            self = .loss
        case "unbeaten", "invaincu", "invincible":
            self = .unbeaten
        case "winless", "sans victoire":
            self = .winless
        default:
            return nil
        }
    }
}

struct TeamStreakInsights: Decodable, Equatable {
    let type: TeamStreakType
    let count: Int

    init(type: TeamStreakType, count: Int) {
        self.type = type
        self.count = count
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let rawType = try container.decodeIfPresent(String.self, forKey: .type)
            ?? container.decodeIfPresent(String.self, forKey: .kind)
            ?? ""
        type = TeamStreakType(rawValue: rawType) ?? .win
        count = SeasonStatsDecoding.int(from: container, forKey: .count)
            ?? SeasonStatsDecoding.int(from: container, forKey: .length)
            ?? 0
    }

    private enum CodingKeys: String, CodingKey {
        case type
        case kind
        case count
        case length
    }
}

struct TeamSeasonSummaryInsights: Decodable, Equatable {
    let played: Int
    let wins: Int
    let draws: Int
    let losses: Int
    let goalsFor: Int
    let goalsAgainst: Int
    let points: Int

    var hasContent: Bool {
        played > 0 || wins > 0 || draws > 0 || losses > 0 || goalsFor > 0 || goalsAgainst > 0 || points > 0
    }

    init(
        played: Int = 0,
        wins: Int = 0,
        draws: Int = 0,
        losses: Int = 0,
        goalsFor: Int = 0,
        goalsAgainst: Int = 0,
        points: Int = 0
    ) {
        self.played = played
        self.wins = wins
        self.draws = draws
        self.losses = losses
        self.goalsFor = goalsFor
        self.goalsAgainst = goalsAgainst
        self.points = points
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        played = SeasonStatsDecoding.int(from: container, forKey: .played)
            ?? SeasonStatsDecoding.int(from: container, forKey: .matchesPlayed)
            ?? 0
        wins = SeasonStatsDecoding.int(from: container, forKey: .wins) ?? 0
        draws = SeasonStatsDecoding.int(from: container, forKey: .draws) ?? 0
        losses = SeasonStatsDecoding.int(from: container, forKey: .losses) ?? 0
        goalsFor = SeasonStatsDecoding.int(from: container, forKey: .goalsFor) ?? 0
        goalsAgainst = SeasonStatsDecoding.int(from: container, forKey: .goalsAgainst) ?? 0
        points = SeasonStatsDecoding.int(from: container, forKey: .points) ?? 0
    }

    private enum CodingKeys: String, CodingKey {
        case played
        case matchesPlayed
        case wins
        case draws
        case losses
        case goalsFor
        case goalsAgainst
        case points
    }
}

struct TeamInsightsPlayerRef: Decodable, Equatable, Identifiable {
    let id: String
    let firstName: String?
    let lastName: String?

    var displayName: String {
        [firstName, lastName]
            .compactMap { $0 }
            .filter { !$0.isEmpty }
            .joined(separator: " ")
    }

    var isGuest: Bool {
        id.hasPrefix("guest_")
    }

    var initials: String {
        let first = firstName?.first.map(String.init) ?? ""
        let last = lastName?.first.map(String.init) ?? ""
        let value = "\(first)\(last)".uppercased()
        return value.isEmpty ? "?" : value
    }

    init(
        id: String,
        firstName: String? = nil,
        lastName: String? = nil
    ) {
        self.id = id
        self.firstName = firstName
        self.lastName = lastName
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decodeIfPresent(String.self, forKey: .userId)
            ?? container.decodeIfPresent(String.self, forKey: .id)
            ?? ""
        firstName = try container.decodeIfPresent(String.self, forKey: .firstName)
        lastName = try container.decodeIfPresent(String.self, forKey: .lastName)
    }

    private enum CodingKeys: String, CodingKey {
        case id
        case userId
        case firstName
        case lastName
    }
}

enum TeamPlayerOfMomentScope: String, Decodable, Equatable {
    case recent
    case season

    init?(rawValue: String) {
        switch rawValue.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() {
        case "recent", "last5", "last5matches", "last_matches", "lastmatches":
            self = .recent
        case "season", "saison":
            self = .season
        default:
            return nil
        }
    }
}

struct TeamPlayerOfMomentInsights: Decodable, Equatable {
    let player: TeamInsightsPlayerRef?
    let goals: Int
    let assists: Int
    let scope: TeamPlayerOfMomentScope?

    var contributions: Int {
        goals + assists
    }

    var hasContent: Bool {
        player != nil && contributions > 0
    }

    init(
        player: TeamInsightsPlayerRef? = nil,
        goals: Int = 0,
        assists: Int = 0,
        scope: TeamPlayerOfMomentScope? = nil
    ) {
        self.player = player
        self.goals = goals
        self.assists = assists
        self.scope = scope
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        player = try container.decodeIfPresent(TeamInsightsPlayerRef.self, forKey: .player)
        goals = SeasonStatsDecoding.int(from: container, forKey: .goals) ?? 0
        assists = SeasonStatsDecoding.int(from: container, forKey: .assists) ?? 0

        if let rawScope = try container.decodeIfPresent(String.self, forKey: .scope)
            ?? container.decodeIfPresent(String.self, forKey: .basedOn) {
            scope = TeamPlayerOfMomentScope(rawValue: rawScope)
        } else {
            scope = nil
        }
    }

    private enum CodingKeys: String, CodingKey {
        case player
        case goals
        case assists
        case scope
        case basedOn
    }
}

struct TeamAvailabilityInsights: Decodable, Equatable {
    let averageResponseRate: Double?
    let nextMatchResponseRate: Double?

    var hasContent: Bool {
        averageResponseRate != nil || nextMatchResponseRate != nil
    }

    init(
        averageResponseRate: Double? = nil,
        nextMatchResponseRate: Double? = nil
    ) {
        self.averageResponseRate = averageResponseRate
        self.nextMatchResponseRate = nextMatchResponseRate
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        averageResponseRate = Self.decodeRate(from: container, forKey: .averageResponseRate)
            ?? Self.decodeRate(from: container, forKey: .averageRate)
        nextMatchResponseRate = Self.decodeRate(from: container, forKey: .nextMatchResponseRate)
            ?? Self.decodeRate(from: container, forKey: .nextMatchRate)
    }

    private enum CodingKeys: String, CodingKey {
        case averageResponseRate
        case averageRate
        case nextMatchResponseRate
        case nextMatchRate
    }

    private static func decodeRate<K: CodingKey>(
        from container: KeyedDecodingContainer<K>,
        forKey key: K
    ) -> Double? {
        if let value = try? container.decodeIfPresent(Double.self, forKey: key) {
            return normalizeRate(value)
        }
        if let value = try? container.decodeIfPresent(Int.self, forKey: key) {
            return normalizeRate(Double(value))
        }
        return nil
    }

    private static func normalizeRate(_ value: Double) -> Double {
        value > 1 ? value / 100 : value
    }

    func formattedPercent(_ rate: Double?) -> String? {
        guard let rate else { return nil }
        let percent = Int((rate * 100).rounded())
        return "\(percent)%"
    }
}

struct TeamNextMatchInsights: Decodable, Equatable {
    let match: TeamInsightsMatchPreview?
    let availability: TeamNextMatchAvailabilitySummary?

    var hasContent: Bool {
        match != nil || availability?.hasContent == true
    }
}

struct TeamInsightsMatchPreview: Decodable, Equatable, Identifiable {
    let id: String
    let title: String?
    let opponentTeam: String?
    let date: Date?
    let startTime: String?
    let status: MatchStatus?

    var displayTitle: String {
        if let title, !title.isEmpty {
            return title
        }
        if let opponentTeam, !opponentTeam.isEmpty {
            return opponentTeam
        }
        return "—"
    }

    init(
        id: String,
        title: String? = nil,
        opponentTeam: String? = nil,
        date: Date? = nil,
        startTime: String? = nil,
        status: MatchStatus? = nil
    ) {
        self.id = id
        self.title = title
        self.opponentTeam = opponentTeam
        self.date = date
        self.startTime = startTime
        self.status = status
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decodeIfPresent(String.self, forKey: .id)
            ?? container.decodeIfPresent(String.self, forKey: .matchId)
            ?? ""
        title = try container.decodeIfPresent(String.self, forKey: .title)
        opponentTeam = try container.decodeIfPresent(String.self, forKey: .opponentTeam)
        startTime = try container.decodeIfPresent(String.self, forKey: .startTime)
        status = try container.decodeIfPresent(MatchStatus.self, forKey: .status)
        date = TeamInsightsDecoding.decodeDate(from: container, forKey: .date)
            ?? TeamInsightsDecoding.decodeDate(from: container, forKey: .matchDate)
    }

    private enum CodingKeys: String, CodingKey {
        case id
        case matchId
        case title
        case opponentTeam
        case date
        case matchDate
        case startTime
        case status
    }
}

struct TeamNextMatchAvailabilitySummary: Decodable, Equatable {
    let available: Int
    let absent: Int
    let unknown: Int

    var hasContent: Bool {
        available > 0 || absent > 0 || unknown > 0
    }

    init(
        available: Int = 0,
        absent: Int = 0,
        unknown: Int = 0
    ) {
        self.available = available
        self.absent = absent
        self.unknown = unknown
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        available = SeasonStatsDecoding.int(from: container, forKey: .available) ?? 0
        absent = SeasonStatsDecoding.int(from: container, forKey: .absent) ?? 0
        unknown = SeasonStatsDecoding.int(from: container, forKey: .unknown) ?? 0
    }

    private enum CodingKeys: String, CodingKey {
        case available
        case absent
        case unknown
    }
}

private enum TeamInsightsDecoding {
    static func decodeDate<K: CodingKey>(
        from container: KeyedDecodingContainer<K>,
        forKey key: K
    ) -> Date? {
        if let date = try? container.decodeIfPresent(Date.self, forKey: key) {
            return date
        }

        guard let raw = try? container.decodeIfPresent(String.self, forKey: key),
              !raw.isEmpty else {
            return nil
        }

        let iso = ISO8601DateFormatter()
        iso.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        if let date = iso.date(from: raw) {
            return date
        }

        iso.formatOptions = [.withInternetDateTime]
        if let date = iso.date(from: raw) {
            return date
        }

        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.date(from: raw)
    }
}
