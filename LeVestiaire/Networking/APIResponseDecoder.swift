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
        let code: String?
    }

    struct APIErrorEnvelope: Decodable {
        let success: Bool?
        let error: String?
        let message: String?
        let code: String?
    }

    static func decodeMeResponse(from data: Data) throws -> MeResponse {
        let decoder = JSONDecoder()

        if let response = try? decoder.decode(MeResponse.self, from: data),
           response.user != nil {
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

    /// Décode un objet contenu dans `data` (payload API), pas l'enveloppe complète.
    static func decodePayload<T: Decodable>(_ type: T.Type, from data: Data) throws -> T {
        let decoder = JSONDecoder()

        if let envelope = try? decoder.decode(DataEnvelope<T>.self, from: data),
           let nested = envelope.data {
            return nested
        }

        if let value = try? decoder.decode(T.self, from: data) {
            return value
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
        let decoder = JSONDecoder()

        if let response = try? decoder.decode(SportProfileResponse.self, from: data),
           response.hasValidData || response.success {
            return response
        }

        if let envelope = try? decoder.decode(DataEnvelope<SportProfileData>.self, from: data),
           let profileData = envelope.data {
            return SportProfileResponse(success: true, data: profileData)
        }

        if let envelope = try? decoder.decode(MessageEnvelope.self, from: data) {
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
        resolveErrorMessage(from: data, fallback: nil)
    }

    /// Résout le message utilisateur depuis `{ success: false, error, code? }`.
    /// Les clés i18n (`error.quiz.not_found`) sont traduites ; les messages FR de l'API sont affichés tels quels.
    static func resolveErrorMessage(from data: Data, fallback: String?) -> String? {
        guard let envelope = try? JSONDecoder().decode(APIErrorEnvelope.self, from: data) else {
            return fallback
        }

        if let error = trimmedNonEmpty(envelope.error) {
            return displayMessage(for: error)
        }

        if let code = trimmedNonEmpty(envelope.code),
           let message = APIErrorLocalizer.messageForAuthCode(code) {
            return message
        }

        if let message = trimmedNonEmpty(envelope.message) {
            return displayMessage(for: message)
        }

        return fallback
    }

    private static func trimmedNonEmpty(_ value: String?) -> String? {
        guard let value else { return nil }
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }

    private static func displayMessage(for raw: String) -> String {
        APIErrorLocalizer.localized(raw) ?? raw
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
