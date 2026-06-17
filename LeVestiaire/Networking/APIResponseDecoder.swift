//
//  APIResponseDecoder.swift
//  LeVestaire
//
//  Created by Corentin Robert on 15/06/2026.
//

import Foundation

enum APIResponseDecoder {
    private struct DataEnvelope<T: Decodable>: Decodable {
        let data: T?
    }

    private struct MessageEnvelope: Decodable {
        let success: Bool?
        let error: String?
        let message: String?
    }

    static func decodeMeResponse(from data: Data) throws -> MeResponse {
        let decoder = JSONDecoder()

        if let response = try? decoder.decode(MeResponse.self, from: data),
           response.user != nil || response.data != nil {
            return response
        }

        throw DecodingError.dataCorrupted(
            DecodingError.Context(
                codingPath: [],
                debugDescription: L10n.decodeApiResponseFailed("MeResponse")
            )
        )
    }

    static func decodeUser(from data: Data) throws -> User {
        if let meResponse = try? decodeMeResponse(from: data),
           let user = meResponse.user {
            return user
        }

        if let envelope = try? JSONDecoder().decode(DataEnvelope<User>.self, from: data),
           let user = envelope.data,
           !user.id.isEmpty {
            return user
        }

        let decoder = JSONDecoder()
        if let user = try? decoder.decode(User.self, from: data),
           !user.id.isEmpty {
            return user
        }

        throw DecodingError.dataCorrupted(
            DecodingError.Context(
                codingPath: [],
                debugDescription: L10n.decodeApiResponseFailed("User")
            )
        )
    }

    static func decode<T: Decodable>(_ type: T.Type, from data: Data) throws -> T {
        let decoder = JSONDecoder()

        if let value = try? decoder.decode(T.self, from: data) {
            return value
        }

        if let envelope = try? decoder.decode(DataEnvelope<T>.self, from: data),
           let nested = envelope.data {
            return nested
        }

        throw DecodingError.dataCorrupted(
            DecodingError.Context(
                codingPath: [],
                debugDescription: L10n.decodeApiResponseFailed(String(describing: type))
            )
        )
    }

    static func decodeLoginResponse(from data: Data) -> LoginResponse {
        if let response = try? decode(LoginResponse.self, from: data) {
            return response
        }

        if let envelope = try? JSONDecoder().decode(MessageEnvelope.self, from: data) {
            return LoginResponse(
                success: envelope.success ?? false,
                message: envelope.message,
                error: envelope.error
            )
        }

        return LoginResponse(
            success: false,
            message: L10n.invalidApiResponse
        )
    }

    static func decodeSportProfileResponse(from data: Data) -> SportProfileResponse {
        if let response = try? decode(SportProfileResponse.self, from: data) {
            return response
        }

        if let envelope = try? JSONDecoder().decode(MessageEnvelope.self, from: data) {
            return SportProfileResponse(
                success: envelope.success ?? false,
                message: envelope.message,
                error: envelope.error
            )
        }

        return SportProfileResponse(
            success: false,
            message: L10n.invalidApiResponse
        )
    }

    static func decodeErrorMessage(from data: Data) -> String? {
        if let envelope = try? JSONDecoder().decode(MessageEnvelope.self, from: data) {
            return envelope.error ?? envelope.message
        }
        return nil
    }

    static func decodeProfilePictureResponse(from data: Data, statusCode: Int) -> ProfilePictureResponse {
        if let response = try? decode(ProfilePictureResponse.self, from: data) {
            if response.imageUrl != nil || response.success {
                return response
            }
        }

        if let envelope = try? JSONDecoder().decode(MessageEnvelope.self, from: data) {
            return ProfilePictureResponse(
                success: envelope.success ?? (200...299).contains(statusCode),
                message: envelope.message ?? envelope.error
            )
        }

        if (200...299).contains(statusCode) {
            return ProfilePictureResponse(success: true)
        }

        return ProfilePictureResponse(
            success: false,
            message: L10n.invalidProfilePictureApiResponse
        )
    }
}
