//
//  PasswordResetResponse.swift
//  LeVestaire
//
//  Created by Corentin Robert on 15/06/2026.
//

import Foundation

struct PasswordResetResponse: Decodable, Equatable {
    let success: Bool
    let message: String?
    let error: String?
    let statusCode: Int?

    init(
        success: Bool = false,
        message: String? = nil,
        error: String? = nil,
        statusCode: Int? = nil
    ) {
        self.success = success
        self.message = message
        self.error = error
        self.statusCode = statusCode
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        success = try container.decodeIfPresent(Bool.self, forKey: .success) ?? false
        message = try container.decodeIfPresent(String.self, forKey: .message)
        error = try container.decodeIfPresent(String.self, forKey: .error)
        statusCode = try container.decodeIfPresent(Int.self, forKey: .statusCode)
    }

    private enum CodingKeys: String, CodingKey {
        case success
        case message
        case error
        case statusCode
    }
}
