//
//  MatchSharedDecoding.swift
//  LeVestaire
//

import Foundation

enum MatchSharedDecoding {
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

    static func parseDateString(_ value: String) -> Date? {
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }
        if let date = iso8601WithFractionalSeconds.date(from: trimmed) {
            return date
        }
        if let date = iso8601.date(from: trimmed) {
            return date
        }
        return dateOnlyFormatter.date(from: trimmed)
    }

    struct TeamReference: Decodable {
        let id: String?
        let mongoId: String?
        let name: String?

        enum CodingKeys: String, CodingKey {
            case id
            case mongoId = "_id"
            case name
        }

        var resolvedId: String? {
            mongoId ?? id
        }

        var resolvedName: String? {
            guard let rawName = name?.trimmingCharacters(in: .whitespacesAndNewlines),
                  !rawName.isEmpty else {
                return nil
            }
            return rawName
        }
    }

    static func resolveTeamId<K: CodingKey>(
        from container: KeyedDecodingContainer<K>,
        teamId: K,
        homeTeam: K,
        team: K
    ) -> String? {
        if let teamId = try? container.decodeIfPresent(String.self, forKey: teamId) {
            return teamId
        }
        if let homeTeam = try? container.decodeIfPresent(String.self, forKey: homeTeam) {
            return homeTeam
        }
        if let homeTeamRef = try? container.decodeIfPresent(TeamReference.self, forKey: homeTeam) {
            return homeTeamRef.resolvedId
        }
        if let team = try? container.decodeIfPresent(TeamReference.self, forKey: team) {
            return team.resolvedId
        }
        return nil
    }

    static func resolveTeamName<K: CodingKey>(
        from container: KeyedDecodingContainer<K>,
        homeTeamName: K,
        homeTeam: K,
        team: K
    ) -> String? {
        if let name = try? container.decodeIfPresent(String.self, forKey: homeTeamName)?
            .trimmingCharacters(in: .whitespacesAndNewlines),
           !name.isEmpty {
            return name
        }
        if let homeTeamRef = try? container.decodeIfPresent(TeamReference.self, forKey: homeTeam) {
            return homeTeamRef.resolvedName
        }
        if let teamRef = try? container.decodeIfPresent(TeamReference.self, forKey: team) {
            return teamRef.resolvedName
        }
        return nil
    }

    /// Verrou de la feuille match : `compositionLocked` sur le match, avec repli API legacy.
    static func resolveCompositionLocked<K: CodingKey>(
        from container: KeyedDecodingContainer<K>,
        compositionLockedKey: K,
        legacyIsCompositionLockedKey: K,
        legacyCompositionIsLocked: Bool? = nil
    ) -> Bool {
        if (try? container.decodeIfPresent(Bool.self, forKey: compositionLockedKey)) == true {
            return true
        }
        if (try? container.decodeIfPresent(Bool.self, forKey: legacyIsCompositionLockedKey)) == true {
            return true
        }
        return legacyCompositionIsLocked == true
    }

    static func resolveCompositionLockedAt<K: CodingKey>(
        from container: KeyedDecodingContainer<K>,
        compositionLockedAtKey: K
    ) -> Date? {
        guard let raw = try? container.decodeIfPresent(String.self, forKey: compositionLockedAtKey) else {
            return nil
        }
        return parseDateString(raw)
    }
}
