//
//  ProfilePictureResponse.swift
//  LeVestaire
//
//  Created by Corentin Robert on 16/06/2026.
//

import Foundation

struct ProfilePictureResponse: Decodable, Equatable {
    let success: Bool
    let message: String?
    let data: ProfilePictureData?
    let url: String?
    let profileImageUrl: String?
    let avatar: String?
    let avatarUrl: String?

    var imageUrl: String? {
        data?.profileImageUrl
            ?? data?.url
            ?? data?.avatar
            ?? data?.avatarUrl
            ?? profileImageUrl
            ?? url
            ?? avatar
            ?? avatarUrl
    }

    init(
        success: Bool = false,
        message: String? = nil,
        data: ProfilePictureData? = nil,
        url: String? = nil,
        profileImageUrl: String? = nil,
        avatar: String? = nil,
        avatarUrl: String? = nil
    ) {
        self.success = success
        self.message = message
        self.data = data
        self.url = url
        self.profileImageUrl = profileImageUrl
        self.avatar = avatar
        self.avatarUrl = avatarUrl
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        success = try container.decodeIfPresent(Bool.self, forKey: .success) ?? false
        message = try container.decodeIfPresent(String.self, forKey: .message)
        data = try container.decodeIfPresent(ProfilePictureData.self, forKey: .data)
        url = try container.decodeIfPresent(String.self, forKey: .url)
        profileImageUrl = try container.decodeIfPresent(String.self, forKey: .profileImageUrl)
        avatar = try container.decodeIfPresent(String.self, forKey: .avatar)
        avatarUrl = try container.decodeIfPresent(String.self, forKey: .avatarUrl)
    }

    private enum CodingKeys: String, CodingKey {
        case success
        case message
        case data
        case url
        case profileImageUrl
        case avatar
        case avatarUrl
    }
}

struct ProfilePictureData: Decodable, Equatable {
    let url: String?
    let profileImageUrl: String?
    let avatar: String?
    let avatarUrl: String?
}
