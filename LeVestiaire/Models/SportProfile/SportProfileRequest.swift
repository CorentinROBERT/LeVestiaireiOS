//
//  SportProfileRequest.swift
//  LeVestaire
//
//  Created by Corentin Robert on 16/06/2026.
//

import Foundation

struct SportProfileRequest: Codable, Equatable {
    let favoriteLeague: String?
    let favoriteTeam: String?
    let strongFoot: String?
    let experienceLevel: Int
    let jerseyNumber: Int?
    let licenseNumber: String?
    let favoritePositions: [String]?
    let playedPositions: [String]?
    let availabilities: [String]?
    let profileImageUrl: String?

    init(
        favoriteLeague: String? = nil,
        favoriteTeam: String? = nil,
        strongFoot: String? = nil,
        experienceLevel: Int,
        jerseyNumber: Int? = nil,
        licenseNumber: String? = nil,
        favoritePositions: [String]? = nil,
        playedPositions: [String]? = nil,
        availabilities: [String]? = nil,
        profileImageUrl: String? = nil
    ) {
        self.favoriteLeague = favoriteLeague
        self.favoriteTeam = favoriteTeam
        self.strongFoot = strongFoot
        self.experienceLevel = experienceLevel
        self.jerseyNumber = jerseyNumber
        self.licenseNumber = licenseNumber
        self.favoritePositions = favoritePositions
        self.playedPositions = playedPositions
        self.availabilities = availabilities
        self.profileImageUrl = profileImageUrl
    }

    static func from(sportProfile: SportProfile) -> SportProfileRequest {
        SportProfileRequest(
            favoriteLeague: sportProfile.favoriteLeague,
            favoriteTeam: sportProfile.favoriteTeam,
            strongFoot: sportProfile.strongFoot,
            experienceLevel: sportProfile.experienceLevel,
            jerseyNumber: sportProfile.jerseyNumber,
            licenseNumber: sportProfile.licenseNumber,
            favoritePositions: sportProfile.favoritePositions,
            playedPositions: sportProfile.playedPositions,
            availabilities: sportProfile.availabilities,
            profileImageUrl: sportProfile.profileImageUrl
        )
    }

    func with(
        favoriteLeague: String?? = nil,
        favoriteTeam: String?? = nil,
        strongFoot: String?? = nil,
        experienceLevel: Int? = nil,
        jerseyNumber: Int?? = nil,
        licenseNumber: String?? = nil,
        favoritePositions: [String]?? = nil,
        playedPositions: [String]?? = nil,
        availabilities: [String]?? = nil,
        profileImageUrl: String?? = nil
    ) -> SportProfileRequest {
        SportProfileRequest(
            favoriteLeague: favoriteLeague ?? self.favoriteLeague,
            favoriteTeam: favoriteTeam ?? self.favoriteTeam,
            strongFoot: strongFoot ?? self.strongFoot,
            experienceLevel: experienceLevel ?? self.experienceLevel,
            jerseyNumber: jerseyNumber ?? self.jerseyNumber,
            licenseNumber: licenseNumber ?? self.licenseNumber,
            favoritePositions: favoritePositions ?? self.favoritePositions,
            playedPositions: playedPositions ?? self.playedPositions,
            availabilities: availabilities ?? self.availabilities,
            profileImageUrl: profileImageUrl ?? self.profileImageUrl
        )
    }
}
