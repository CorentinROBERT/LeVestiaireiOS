//
//  SportProfileService.swift
//  LeVestaire
//
//  Created by Corentin Robert on 16/06/2026.
//

import Foundation
import UIKit

final class SportProfileService {
    static let shared = SportProfileService(
        client: APIClient.shared,
        authService: AuthService.shared
    )

    private static let profilePictureFieldName = "profilePicture"

    private let client: APIClient
    private let authService: AuthService

    init(client: APIClient, authService: AuthService) {
        self.client = client
        self.authService = authService
    }

    @MainActor
    func saveProfile(_ request: SportProfileRequest) async -> SportProfileResponse {
        guard let accessToken = authService.authToken, !accessToken.isEmpty else {
            return SportProfileResponse(
                success: false,
                message: "Session requise. Veuillez vous reconnecter."
            )
        }

        do {
            let body = try JSONEncoder().encode(request)
            let (data, _) = try await client.request(
                path: APIEndpoints.sportProfile,
                method: "POST",
                body: body,
                headers: authorizationHeader(accessToken: accessToken)
            )

            return APIResponseDecoder.decodeSportProfileResponse(from: data)
        } catch {
            return SportProfileResponse(
                success: false,
                message: "Erreur lors de l'enregistrement du profil sportif: \(error.localizedDescription)"
            )
        }
    }

    @MainActor
    func uploadProfilePicture(_ image: UIImage) async -> ProfilePictureResponse {
        guard let accessToken = authService.authToken, !accessToken.isEmpty else {
            return ProfilePictureResponse(
                success: false,
                message: "Session requise. Veuillez vous reconnecter."
            )
        }

        guard let imageData = image.jpegData(compressionQuality: 0.85) else {
            return ProfilePictureResponse(
                success: false,
                message: "Impossible de préparer la photo de profil."
            )
        }

        do {
            let (data, httpResponse) = try await client.uploadMultipart(
                path: APIEndpoints.profilePicture,
                fieldName: Self.profilePictureFieldName,
                fileName: "profile.jpg",
                mimeType: "image/jpeg",
                fileData: imageData,
                headers: authorizationHeader(accessToken: accessToken)
            )

            return APIResponseDecoder.decodeProfilePictureResponse(
                from: data,
                statusCode: httpResponse.statusCode
            )
        } catch {
            return ProfilePictureResponse(
                success: false,
                message: "Erreur lors de l'upload de la photo: \(error.localizedDescription)"
            )
        }
    }

    private func authorizationHeader(accessToken: String) -> [String: String] {
        ["Authorization": "Bearer \(accessToken)"]
    }
}
