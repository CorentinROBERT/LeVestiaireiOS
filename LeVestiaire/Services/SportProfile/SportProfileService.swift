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
    func fetchProfile() async -> SportProfileResponse {
        guard let accessToken = authService.authToken, !accessToken.isEmpty else {
            return SportProfileResponse(
                success: false,
                message: L10n.sessionRequired
            )
        }

        do {
            let (data, httpResponse) = try await client.request(
                path: APIEndpoints.sportProfile,
                method: "GET",
                headers: AuthenticatedAPIClient.bearerHeader(accessToken: accessToken)
            )

            if httpResponse.statusCode == 404 {
                return SportProfileResponse(success: false)
            }

            return APIResponseDecoder.decodeSportProfileResponse(from: data)
        } catch {
            return SportProfileResponse(
                success: false,
                message: error.localizedDescription
            )
        }
    }

    @MainActor
    func saveProfile(_ request: SportProfileRequest) async -> SportProfileResponse {
        guard let accessToken = authService.authToken, !accessToken.isEmpty else {
            return SportProfileResponse(
                success: false,
                message: L10n.sessionRequired
            )
        }

        do {
            let body = try JSONEncoder().encode(request)
            let (data, response) = try await client.request(
                path: APIEndpoints.sportProfile,
                method: "POST",
                body: body,
                headers: AuthenticatedAPIClient.bearerHeader(accessToken: accessToken)
            )

            guard HTTPResponseValidator.isSuccess(response) else {
                return SportProfileResponse(
                    success: false,
                    message: HTTPResponseValidator.localizedErrorMessage(
                        from: data,
                        fallback: L10n.text("saveSportProfileError")
                    )
                )
            }

            return APIResponseDecoder.decodeSportProfileResponse(from: data)
        } catch {
            return SportProfileResponse(
                success: false,
                message: L10n.saveSportProfileErrorWithDetail(error.localizedDescription)
            )
        }
    }

    @MainActor
    func uploadProfilePicture(_ image: UIImage) async -> ProfilePictureResponse {
        guard let accessToken = authService.authToken, !accessToken.isEmpty else {
            return ProfilePictureResponse(
                success: false,
                message: L10n.sessionRequired
            )
        }

        guard let imageData = image.jpegData(compressionQuality: 0.85) else {
            return ProfilePictureResponse(
                success: false,
                message: L10n.prepareProfilePhotoFailed
            )
        }

        do {
            let (data, httpResponse) = try await client.uploadMultipart(
                path: APIEndpoints.profilePicture,
                fieldName: Self.profilePictureFieldName,
                fileName: "profile.jpg",
                mimeType: "image/jpeg",
                fileData: imageData,
                headers: AuthenticatedAPIClient.bearerHeader(accessToken: accessToken)
            )

            return APIResponseDecoder.decodeProfilePictureResponse(
                from: data,
                statusCode: httpResponse.statusCode
            )
        } catch {
            return ProfilePictureResponse(
                success: false,
                message: L10n.uploadPhotoErrorWithDetail(error.localizedDescription)
            )
        }
    }
}
