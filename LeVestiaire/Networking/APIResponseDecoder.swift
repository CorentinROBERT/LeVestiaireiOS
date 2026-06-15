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
                debugDescription: "Impossible de décoder \(T.self) depuis la réponse API."
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
            message: "Réponse API invalide."
        )
    }
}
