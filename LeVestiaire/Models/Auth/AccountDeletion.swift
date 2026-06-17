//
//  AccountDeletion.swift
//  LeVestaire
//
//  Created by Corentin Robert on 15/06/2026.
//

import Foundation

/// Demande de suppression de compte en cours.
struct AccountDeletion: Decodable, Equatable {
    let hasPendingDeletion: Bool
    let requestedAt: Date
    let scheduledFor: Date
    let daysRemaining: Int
    let canCancel: Bool

    init(
        hasPendingDeletion: Bool = false,
        requestedAt: Date,
        scheduledFor: Date,
        daysRemaining: Int = 0,
        canCancel: Bool = true
    ) {
        self.hasPendingDeletion = hasPendingDeletion
        self.requestedAt = requestedAt
        self.scheduledFor = scheduledFor
        self.daysRemaining = daysRemaining
        self.canCancel = canCancel
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        hasPendingDeletion = try container.decodeIfPresent(Bool.self, forKey: .hasPendingDeletion) ?? false
        daysRemaining = try container.decodeIfPresent(Int.self, forKey: .daysRemaining) ?? 0
        canCancel = try container.decodeIfPresent(Bool.self, forKey: .canCancel) ?? true

        requestedAt = try Self.decodeRequiredDate(from: container, forKey: .requestedAt)
        scheduledFor = try Self.decodeRequiredDate(from: container, forKey: .scheduledFor)
    }

    private enum CodingKeys: String, CodingKey {
        case hasPendingDeletion
        case requestedAt
        case scheduledFor
        case daysRemaining
        case canCancel
    }

    private static func decodeRequiredDate(
        from container: KeyedDecodingContainer<CodingKeys>,
        forKey key: CodingKeys
    ) throws -> Date {
        guard let date = UserJSONParsing.parseDate(from: container, forKey: key) else {
            throw DecodingError.dataCorruptedError(
                forKey: key,
                in: container,
                debugDescription: L10n.invalidDateOrMissing
            )
        }

        return date
    }
}
