//
//  MeResponse.swift
//  LeVestaire
//
//  Created by Corentin Robert on 17/06/2026.
//

import Foundation

struct MeSessionData: Decodable, Equatable {
    let user: User?
    let token: String?
    let refreshToken: String?
}

/// Réponse de `GET /api/v1/me` (et login avec suppression en cours).
/// `accountDeletion` est au niveau racine ; l'utilisateur est dans `data` ou `data.user`.
struct MeResponse: Decodable, Equatable {
    let success: Bool?
    let message: String?
    let accountDeletion: AccountDeletion?
    private let sessionData: MeSessionData?
    private let directUser: User?

    var user: User? {
        let baseUser = sessionData?.user ?? directUser
        guard let baseUser, !baseUser.id.isEmpty else { return nil }

        if let accountDeletion {
            return baseUser.with(accountDeletion: accountDeletion)
        }

        return baseUser
    }

    var accessToken: String? {
        sessionData?.token
    }

    var refreshToken: String? {
        sessionData?.refreshToken
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        success = try container.decodeIfPresent(Bool.self, forKey: .success)
        message = try container.decodeIfPresent(String.self, forKey: .message)
        accountDeletion = try container.decodeIfPresent(AccountDeletion.self, forKey: .accountDeletion)

        if let session = try? container.decode(MeSessionData.self, forKey: .data),
           let user = session.user,
           !user.id.isEmpty {
            sessionData = session
            directUser = nil
        } else if let user = try? container.decode(User.self, forKey: .data),
                  !user.id.isEmpty {
            sessionData = nil
            directUser = user
        } else {
            sessionData = nil
            directUser = nil
        }
    }

    private enum CodingKeys: String, CodingKey {
        case success
        case message
        case data
        case accountDeletion
    }
}
