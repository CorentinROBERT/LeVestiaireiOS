//
//  MeResponse.swift
//  LeVestaire
//
//  Created by Corentin Robert on 17/06/2026.
//

import Foundation

/// Réponse de `GET /api/v1/me`.
/// L'utilisateur est dans `data` ; `accountDeletion` est au niveau racine.
struct MeResponse: Decodable, Equatable {
    let success: Bool?
    let message: String?
    let data: User?
    let accountDeletion: AccountDeletion?

    var user: User? {
        guard let data, !data.id.isEmpty else { return nil }

        if let accountDeletion {
            return data.with(accountDeletion: accountDeletion)
        }

        return data
    }
}
