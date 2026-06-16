//
//  SportProfile.swift
//  LeVestaire
//
//  Created by Corentin Robert on 16/06/2026.
//

import Foundation

struct SportProfile: Equatable {
    let userId: String
    let isCompleted: Bool
    let createdAt: Date
    let updatedAt: Date
    let favoriteLeague: String?
    let favoriteTeam: String?
    let strongFoot: String?
    let experienceLevel: Int
    let jerseyNumber: Int?
    let licenseNumber: String?
    let availabilities: [String]
    let favoritePositions: [String]
    let playedPositions: [String]
    let profileImageUrl: String?
    let completedAt: Date?
}
