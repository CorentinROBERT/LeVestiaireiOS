//
//  EmailVerificationResponse.swift
//  LeVestaire
//
//  Created by Corentin Robert on 15/06/2026.
//

import Foundation

struct EmailVerificationResponse: Decodable, Equatable {
    let success: Bool
    let message: String?
    let data: EmailVerificationData?

    var email: String? {
        data?.email
    }

    var emailVerified: Bool? {
        data?.emailVerified
    }

    var isActive: Bool? {
        data?.isActive
    }

    init(
        success: Bool = false,
        message: String? = nil,
        data: EmailVerificationData? = nil
    ) {
        self.success = success
        self.message = message
        self.data = data
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        success = try container.decodeIfPresent(Bool.self, forKey: .success) ?? false
        message = try container.decodeIfPresent(String.self, forKey: .message)
        data = try container.decodeIfPresent(EmailVerificationData.self, forKey: .data)
    }

    private enum CodingKeys: String, CodingKey {
        case success
        case message
        case data
    }
}

struct EmailVerificationData: Decodable, Equatable {
    let email: String?
    let emailVerified: Bool?
    let isActive: Bool?
}
