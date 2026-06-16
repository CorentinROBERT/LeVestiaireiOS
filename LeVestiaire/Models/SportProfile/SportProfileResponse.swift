//
//  SportProfileResponse.swift
//  LeVestaire
//
//  Created by Corentin Robert on 16/06/2026.
//

import Foundation

struct SportProfileResponse: Decodable, Equatable {
    let success: Bool
    let message: String?
    let error: String?
    let data: SportProfileData?

    var hasValidData: Bool {
        data != nil
    }

    var sportProfile: SportProfileData? {
        data
    }

    var userFacingMessage: String? {
        message ?? error
    }

    init(
        success: Bool = false,
        message: String? = nil,
        error: String? = nil,
        data: SportProfileData? = nil
    ) {
        self.success = success
        self.message = message
        self.error = error
        self.data = data
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        success = try container.decodeIfPresent(Bool.self, forKey: .success) ?? false
        message = try container.decodeIfPresent(String.self, forKey: .message)
        error = try container.decodeIfPresent(String.self, forKey: .error)
        data = try container.decodeIfPresent(SportProfileData.self, forKey: .data)
    }

    private enum CodingKeys: String, CodingKey {
        case success
        case message
        case error
        case data
    }
}

struct SportProfileData: Decodable, Equatable, Identifiable {
    let id: String
    let userId: String
    let favoriteLeague: String?
    let favoriteTeam: String?
    let strongFoot: String?
    let experienceLevel: Int?
    let favoritePositions: [String]?
    let playedPositions: [String]?
    let availabilities: [String]?
    let profileImageUrl: String?
    let isCompleted: Bool?
    let completedAt: Date?
    let createdAt: Date
    let updatedAt: Date
    let jerseyNumber: Int?
    let licenseNumber: String?

    var isRecent: Bool {
        let thirtyDaysAgo = Calendar.current.date(byAdding: .day, value: -30, to: Date()) ?? Date()
        return updatedAt > thirtyDaysAgo
    }

    var createdAtFormatted: String {
        Self.dateFormatter.string(from: createdAt)
    }

    var updatedAtFormatted: String {
        Self.dateFormatter.string(from: updatedAt)
    }

    var timeSinceCreation: String {
        let difference = Date().timeIntervalSince(createdAt)
        let days = Int(difference / 86_400)
        let hours = Int(difference / 3_600)
        let minutes = Int(difference / 60)

        if days > 0 {
            return days == 1 ? "1 jour" : "\(days) jours"
        }
        if hours > 0 {
            return hours == 1 ? "1 heure" : "\(hours) heures"
        }
        return minutes <= 1 ? "1 minute" : "\(minutes) minutes"
    }

    func toSportProfile() -> SportProfile {
        SportProfile(
            userId: userId,
            isCompleted: isCompleted ?? false,
            createdAt: createdAt,
            updatedAt: updatedAt,
            favoriteLeague: favoriteLeague,
            favoriteTeam: favoriteTeam,
            strongFoot: strongFoot,
            experienceLevel: experienceLevel ?? 1,
            jerseyNumber: jerseyNumber,
            licenseNumber: licenseNumber,
            availabilities: availabilities ?? [],
            favoritePositions: favoritePositions ?? [],
            playedPositions: playedPositions ?? [],
            profileImageUrl: profileImageUrl,
            completedAt: completedAt
        )
    }

    init(
        id: String,
        userId: String,
        favoriteLeague: String? = nil,
        favoriteTeam: String? = nil,
        strongFoot: String? = nil,
        experienceLevel: Int? = nil,
        favoritePositions: [String]? = nil,
        playedPositions: [String]? = nil,
        availabilities: [String]? = nil,
        profileImageUrl: String? = nil,
        isCompleted: Bool? = nil,
        completedAt: Date? = nil,
        createdAt: Date = Date(),
        updatedAt: Date = Date(),
        jerseyNumber: Int? = nil,
        licenseNumber: String? = nil
    ) {
        self.id = id
        self.userId = userId
        self.favoriteLeague = favoriteLeague
        self.favoriteTeam = favoriteTeam
        self.strongFoot = strongFoot
        self.experienceLevel = experienceLevel
        self.favoritePositions = favoritePositions
        self.playedPositions = playedPositions
        self.availabilities = availabilities
        self.profileImageUrl = profileImageUrl
        self.isCompleted = isCompleted
        self.completedAt = completedAt
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.jerseyNumber = jerseyNumber
        self.licenseNumber = licenseNumber
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        id = try container.decodeIfPresent(String.self, forKey: .mongoId)
            ?? container.decodeIfPresent(String.self, forKey: .id)
            ?? ""
        userId = try container.decodeIfPresent(String.self, forKey: .userId) ?? ""
        favoriteLeague = try container.decodeIfPresent(String.self, forKey: .favoriteLeague)
        favoriteTeam = try container.decodeIfPresent(String.self, forKey: .favoriteTeam)
        strongFoot = try container.decodeIfPresent(String.self, forKey: .strongFoot)
        experienceLevel = try container.decodeIfPresent(Int.self, forKey: .experienceLevel)
        favoritePositions = try container.decodeIfPresent([String].self, forKey: .favoritePositions)
        playedPositions = try container.decodeIfPresent([String].self, forKey: .playedPositions)
        availabilities = try container.decodeIfPresent([String].self, forKey: .availabilities)
        profileImageUrl = try container.decodeIfPresent(String.self, forKey: .profileImageUrl)
        isCompleted = try container.decodeIfPresent(Bool.self, forKey: .isCompleted)
        completedAt = UserJSONParsing.parseDate(from: container, forKey: .completedAt)
        createdAt = UserJSONParsing.parseDate(from: container, forKey: .createdAt) ?? Date()
        updatedAt = UserJSONParsing.parseDate(from: container, forKey: .updatedAt) ?? Date()
        jerseyNumber = try container.decodeIfPresent(Int.self, forKey: .jerseyNumber)
        licenseNumber = try container.decodeIfPresent(String.self, forKey: .licenseNumber)
    }

    private enum CodingKeys: String, CodingKey {
        case mongoId = "_id"
        case id
        case userId
        case favoriteLeague
        case favoriteTeam
        case strongFoot
        case experienceLevel
        case favoritePositions
        case playedPositions
        case availabilities
        case profileImageUrl
        case isCompleted
        case completedAt
        case createdAt
        case updatedAt
        case jerseyNumber
        case licenseNumber
    }

    private static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "d/M/yyyy"
        return formatter
    }()
}
