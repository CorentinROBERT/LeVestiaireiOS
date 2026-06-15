//
//  LoginResponse.swift
//  LeVestaire
//
//  Created by Corentin Robert on 15/06/2026.
//

import Foundation

struct LoginResponse: Decodable, Equatable {
    let success: Bool
    let message: String?
    let error: String?
    let data: LoginData?
    let statusCode: Int?
    let emailVerified: Bool?
    let requiresVerification: Bool?

    var hasValidData: Bool {
        data?.user != nil && data?.token != nil
    }

    var user: User? {
        data?.user
    }

    var accessToken: String? {
        data?.token
    }

    var refreshToken: String? {
        data?.refreshToken
    }

    var isEmailVerified: Bool? {
        emailVerified
    }

    init(
        success: Bool = false,
        message: String? = nil,
        error: String? = nil,
        data: LoginData? = nil,
        statusCode: Int? = nil,
        emailVerified: Bool? = nil,
        requiresVerification: Bool? = nil
    ) {
        self.success = success
        self.message = message
        self.error = error
        self.data = data
        self.statusCode = statusCode
        self.emailVerified = emailVerified
        self.requiresVerification = requiresVerification
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        success = try container.decodeIfPresent(Bool.self, forKey: .success) ?? false
        message = try container.decodeIfPresent(String.self, forKey: .message)
        error = try container.decodeIfPresent(String.self, forKey: .error)
        data = try container.decodeIfPresent(LoginData.self, forKey: .data)
        statusCode = try container.decodeIfPresent(Int.self, forKey: .statusCode)
        emailVerified = try container.decodeIfPresent(Bool.self, forKey: .emailVerified)
        requiresVerification = try container.decodeIfPresent(Bool.self, forKey: .requiresVerification)
    }

    private enum CodingKeys: String, CodingKey {
        case success
        case message
        case error
        case data
        case statusCode
        case emailVerified
        case requiresVerification
    }
}

struct LoginData: Decodable, Equatable {
    let user: User?
    let token: String?
    let refreshToken: String?

    var hasToken: Bool {
        guard let token else { return false }
        return !token.isEmpty
    }

    var hasRefreshToken: Bool {
        guard let refreshToken else { return false }
        return !refreshToken.isEmpty
    }
}
