//
//  MatchItem.swift
//  LeVestaire
//
//  Created by Corentin Robert on 17/06/2026.
//

import Foundation

struct MatchItem: Identifiable, Decodable, Hashable {
    let id: String
    let title: String
    let status: MatchStatus
    let opponentTeam: String?
    let location: String?
    let homeTeamName: String?
    let date: Date
    let startTime: String?
    let homeScore: Int?
    let awayScore: Int?

    var scoreText: String? {
        guard let homeScore, let awayScore else { return nil }
        return "\(homeScore) - \(awayScore)"
    }

    var showsScore: Bool {
        status == .finished || status == .ongoing
    }

    var formattedDate: String {
        Self.makeDisplayDateFormatter().string(from: date)
    }

    var formattedTime: String? {
        if let startTime, !startTime.isEmpty {
            return startTime
        }
        return Self.makeDisplayTimeFormatter().string(from: date)
    }

    init(
        id: String,
        title: String,
        status: MatchStatus,
        opponentTeam: String? = nil,
        location: String? = nil,
        homeTeamName: String? = nil,
        date: Date,
        startTime: String? = nil,
        homeScore: Int? = nil,
        awayScore: Int? = nil
    ) {
        self.id = id
        self.title = title
        self.status = status
        self.opponentTeam = opponentTeam
        self.location = location
        self.homeTeamName = homeTeamName
        self.date = date
        self.startTime = startTime
        self.homeScore = homeScore
        self.awayScore = awayScore
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        id = try container.decodeIfPresent(String.self, forKey: .mongoId)
            ?? container.decodeIfPresent(String.self, forKey: .id)
            ?? ""
        title = try container.decodeIfPresent(String.self, forKey: .title) ?? L10n.defaultMatchTitle
        status = try container.decodeIfPresent(MatchStatus.self, forKey: .status) ?? .upcoming
        opponentTeam = try container.decodeIfPresent(String.self, forKey: .opponentTeam)
        location = try container.decodeIfPresent(String.self, forKey: .location)
        homeTeamName = try container.decodeIfPresent(String.self, forKey: .homeTeamName)
        startTime = try container.decodeIfPresent(String.self, forKey: .startTime)
            ?? container.decodeIfPresent(String.self, forKey: .time)
        homeScore = try container.decodeIfPresent(Int.self, forKey: .homeScore)
            ?? container.decodeIfPresent(Int.self, forKey: .scoreHome)
        awayScore = try container.decodeIfPresent(Int.self, forKey: .awayScore)
            ?? container.decodeIfPresent(Int.self, forKey: .scoreAway)
        date = Self.parseDate(from: container) ?? Date()
    }

    private enum CodingKeys: String, CodingKey {
        case mongoId = "_id"
        case id
        case title
        case status
        case opponentTeam
        case location
        case homeTeamName
        case date
        case matchDate
        case startTime
        case time
        case homeScore
        case awayScore
        case scoreHome
        case scoreAway
    }

    private static func makeDisplayDateFormatter() -> DateFormatter {
        let formatter = DateFormatter()
        formatter.locale = LocalizationManager.shared.locale
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter
    }

    private static func makeDisplayTimeFormatter() -> DateFormatter {
        let formatter = DateFormatter()
        formatter.locale = LocalizationManager.shared.locale
        formatter.dateStyle = .none
        formatter.timeStyle = .short
        return formatter
    }

    private static let iso8601WithFractionalSeconds: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter
    }()

    private static let iso8601: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime]
        return formatter
    }()

    private static let dateOnlyFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }()

    private static func parseDate(from container: KeyedDecodingContainer<CodingKeys>) -> Date? {
        if let dateString = try? container.decodeIfPresent(String.self, forKey: .date)
            ?? container.decodeIfPresent(String.self, forKey: .matchDate) {
            return parseDateString(dateString)
        }
        return nil
    }

    private static func parseDateString(_ value: String) -> Date? {
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        if let date = iso8601WithFractionalSeconds.date(from: trimmed) {
            return date
        }
        if let date = iso8601.date(from: trimmed) {
            return date
        }
        return dateOnlyFormatter.date(from: trimmed)
    }
}
