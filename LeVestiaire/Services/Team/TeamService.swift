//
//  TeamService.swift
//  LeVestaire
//

import Foundation
import UIKit

enum TeamServiceError: LocalizedError {
    case unauthorized
    case requestFailed(String)

    var errorDescription: String? {
        switch self {
        case .unauthorized:
            return L10n.sessionRequired
        case .requestFailed(let message):
            return message
        }
    }
}

final class TeamService {
    static let shared = TeamService(
        client: APIClient.shared,
        authService: AuthService.shared
    )

    private static let teamLogoFieldName = "teamLogo"

    private let client: APIClient
    private let authService: AuthService

    init(client: APIClient, authService: AuthService) {
        self.client = client
        self.authService = authService
    }

    @MainActor
    func fetchMyTeams() async throws -> MyTeamsResponse {
        let (data, response) = try await authorizedRequest(
            path: APIEndpoints.teamsMe,
            method: "GET"
        )
        try validate(response: response, data: data, fallback: L10n.text("errorTeamLoading"))
        return try TeamDecoding.decodeMyTeams(from: data)
    }

    @MainActor
    func fetchUserTeams() async throws -> [SquadTeam] {
        try await fetchMyTeams().teams
    }

    @MainActor
    func fetchTeam(id: String) async throws -> SquadTeam {
        let path = APIEndpoints.buildURL(APIEndpoints.teamById, pathParams: ["id": id])
        let (data, response) = try await authorizedRequest(path: path, method: "GET")
        try validate(response: response, data: data, fallback: L10n.text("teamNotFound"))
        return try TeamDecoding.decodeTeam(from: data)
    }

    @MainActor
    func createTeam(
        name: String,
        description: String?,
        logo: UIImage?
    ) async throws -> SquadTeam {
        guard let userId = authService.currentUser?.id, !userId.isEmpty else {
            throw TeamServiceError.unauthorized
        }

        if let logo, let imageData = logo.jpegData(compressionQuality: 0.85) {
            let (data, response) = try await authorizedMultipart(
                path: APIEndpoints.teams,
                method: "POST",
                fields: [
                    "name": name,
                    "description": description ?? "",
                    "userId": userId
                ],
                fileName: "team-logo.jpg",
                fileData: imageData
            )
            try validate(response: response, data: data, fallback: L10n.text("errorTeamCreation"))
            return try TeamDecoding.decodeTeam(from: data)
        }

        let body = try JSONEncoder().encode(
            CreateTeamRequest(name: name, description: description, userId: userId)
        )
        let (data, response) = try await authorizedRequest(
            path: APIEndpoints.teams,
            method: "POST",
            body: body
        )
        try validate(response: response, data: data, fallback: L10n.text("errorTeamCreation"))
        return try TeamDecoding.decodeTeam(from: data)
    }

    @MainActor
    func updateTeam(
        id: String,
        name: String?,
        description: String?,
        logo: UIImage?
    ) async throws -> SquadTeam {
        let path = APIEndpoints.updateTeam(id)

        if let logo, let imageData = logo.jpegData(compressionQuality: 0.85) {
            var fields: [String: String] = [:]
            if let name { fields["name"] = name }
            if let description { fields["description"] = description }

            let (data, response) = try await authorizedMultipart(
                path: path,
                method: "PUT",
                fields: fields,
                fileName: "team-logo.jpg",
                fileData: imageData
            )
            try validate(response: response, data: data, fallback: L10n.text("errorTeamUpdate"))
            return try TeamDecoding.decodeTeam(from: data)
        }

        let body = try JSONEncoder().encode(UpdateTeamRequest(name: name, description: description))
        let (data, response) = try await authorizedRequest(
            path: path,
            method: "PUT",
            body: body
        )
        try validate(response: response, data: data, fallback: L10n.text("errorTeamUpdate"))
        return try TeamDecoding.decodeTeam(from: data)
    }

    @MainActor
    func deleteTeam(id: String) async throws {
        let path = APIEndpoints.updateTeam(id)
        let (data, response) = try await authorizedRequest(path: path, method: "DELETE")
        try validate(response: response, data: data, fallback: L10n.text("errorTeamDeletion"))
    }

    @MainActor
    func leaveTeam(id: String) async throws {
        let (data, response) = try await authorizedRequest(
            path: APIEndpoints.leaveTeam(id),
            method: "POST"
        )
        try validate(response: response, data: data, fallback: L10n.text("errorTeamUpdate"))
    }

    @MainActor
    func invitePlayer(
        teamId: String,
        email: String,
        firstName: String?,
        lastName: String?
    ) async throws {
        let body = try JSONEncoder().encode(
            InvitePlayerRequest(
                email: email,
                firstName: firstName,
                lastName: lastName
            )
        )
        let (data, response) = try await authorizedRequest(
            path: APIEndpoints.teamInvite(teamId),
            method: "POST",
            body: body
        )
        try validate(response: response, data: data, fallback: L10n.text("errorTeamUpdate"))
    }

    @MainActor
    func fetchTeamInvitations(teamId: String) async throws -> [TeamInvitation] {
        let (data, response) = try await authorizedRequest(
            path: APIEndpoints.teamInvitations(teamId),
            method: "GET"
        )
        try validate(response: response, data: data, fallback: L10n.text("errorTeamLoading"))
        return try TeamInvitationDecoding.decodeList(from: data)
    }

    @MainActor
    func resendInvitation(invitationId: String) async throws {
        let (data, response) = try await authorizedRequest(
            path: APIEndpoints.resendInvitation(invitationId),
            method: "POST"
        )
        try validate(response: response, data: data, fallback: L10n.text("errorTeamUpdate"))
    }

    @MainActor
    func cancelInvitation(invitationId: String) async throws {
        let (data, response) = try await authorizedRequest(
            path: APIEndpoints.cancelInvitation(invitationId),
            method: "DELETE"
        )
        try validate(response: response, data: data, fallback: L10n.text("errorTeamUpdate"))
    }

    @MainActor
    func fetchTeamInviteLink(teamId: String) async throws -> TeamInviteLink {
        let (data, response) = try await authorizedRequest(
            path: APIEndpoints.teamInvite(teamId),
            method: "GET"
        )
        try validate(response: response, data: data, fallback: L10n.text("errorTeamLoading"))
        return try APIResponseDecoder.decodePayload(TeamInviteLink.self, from: data)
    }

    @MainActor
    func regenerateTeamInviteLink(teamId: String) async throws -> TeamInviteLink {
        let (data, response) = try await authorizedRequest(
            path: APIEndpoints.teamInviteRegenerate(teamId),
            method: "POST",
            body: Data()
        )
        try validate(response: response, data: data, fallback: L10n.text("errorTeamUpdate"))
        return try APIResponseDecoder.decodePayload(TeamInviteLink.self, from: data)
    }

    @MainActor
    func validateTeamInviteCode(_ code: String) async throws -> TeamInviteValidation {
        let (data, response) = try await client.request(
            path: APIEndpoints.teamInviteByCode(code),
            method: "GET"
        )
        try validate(response: response, data: data, fallback: L10n.text("errorTeamLoading"))
        return try APIResponseDecoder.decodePayload(TeamInviteValidation.self, from: data)
    }

    /// Rejoint une équipe via code d'invitation.
    /// API : `POST /api/v1/teams/join` avec body `{ "teamInviteCode": "..." }`.
    @MainActor
    func joinTeam(inviteCode: String) async throws -> SquadTeam {
        let body = try JSONEncoder().encode(JoinTeamRequest(teamInviteCode: inviteCode))
        let (data, response) = try await authorizedRequest(
            path: APIEndpoints.teamsJoin,
            method: "POST",
            body: body
        )
        try validate(response: response, data: data, fallback: L10n.text("errorTeamUpdate"))

        if let joinResponse = try? APIResponseDecoder.decode(JoinTeamResponse.self, from: data),
           let team = joinResponse.team {
            return team
        }

        return try TeamDecoding.decodeTeam(from: data)
    }

    @MainActor
    func addGuest(teamId: String, request: CreateGuestRequest) async throws {
        let body = try JSONEncoder().encode(request)
        let (data, response) = try await authorizedRequest(
            path: APIEndpoints.createTeamGuest(teamId),
            method: "POST",
            body: body
        )
        try validate(response: response, data: data, fallback: L10n.text("errorTeamUpdate"))
    }

    @MainActor
    func fetchTeamGuests(teamId: String) async throws -> [TeamGuest] {
        let (data, response) = try await authorizedRequest(
            path: APIEndpoints.teamGuests(teamId),
            method: "GET"
        )
        try validate(response: response, data: data, fallback: L10n.text("errorTeamLoading"))
        return try TeamGuestDecoding.decodeList(from: data)
    }

    @MainActor
    func deleteGuest(guestId: String) async throws {
        let (data, response) = try await authorizedRequest(
            path: APIEndpoints.guestById(guestId),
            method: "DELETE"
        )
        try validate(response: response, data: data, fallback: L10n.text("errorTeamUpdate"))
    }

    @MainActor
    func mergeGuest(guestId: String, userId: String) async throws {
        let body = try JSONEncoder().encode(MergeGuestRequest(userId: userId))
        let (data, response) = try await authorizedRequest(
            path: APIEndpoints.mergeGuest(guestId),
            method: "POST",
            body: body
        )
        try validate(response: response, data: data, fallback: L10n.text("errorTeamUpdate"))
    }

    @MainActor
    func updateMemberRole(teamId: String, memberId: String, role: TeamRole) async throws -> SquadTeam {
        let body = try JSONEncoder().encode(UpdateMemberRoleRequest(role: role.rawValue))
        let (data, response) = try await authorizedRequest(
            path: APIEndpoints.updateMemberRole(teamId: teamId, memberId: memberId),
            method: "PUT",
            body: body
        )
        try validate(response: response, data: data, fallback: L10n.text("errorTeamUpdate"))
        return try TeamDecoding.decodeTeam(from: data)
    }

    @MainActor
    func removeMember(teamId: String, memberId: String) async throws {
        let (data, response) = try await authorizedRequest(
            path: APIEndpoints.removeMember(teamId: teamId, memberId: memberId),
            method: "DELETE"
        )
        try validate(response: response, data: data, fallback: L10n.text("errorTeamUpdate"))
    }

    @MainActor
    private func authorizedRequest(
        path: String,
        method: String,
        body: Data? = nil
    ) async throws -> (Data, HTTPURLResponse) {
        do {
            return try await AuthenticatedAPIClient.performRequest(
                client: client,
                authService: authService,
                path: path,
                method: method,
                body: body
            )
        } catch ServiceAuthError.unauthorized {
            throw TeamServiceError.unauthorized
        }
    }

    @MainActor
    private func authorizedMultipart(
        path: String,
        method: String,
        fields: [String: String],
        fileName: String,
        fileData: Data
    ) async throws -> (Data, HTTPURLResponse) {
        do {
            return try await AuthenticatedAPIClient.performMultipartRequest(
                client: client,
                authService: authService,
                path: path,
                method: method,
                fieldName: Self.teamLogoFieldName,
                fileName: fileName,
                mimeType: "image/jpeg",
                fileData: fileData,
                additionalFields: fields
            )
        } catch ServiceAuthError.unauthorized {
            throw TeamServiceError.unauthorized
        }
    }

    private func validate(response: HTTPURLResponse, data: Data, fallback: String) throws {
        guard HTTPResponseValidator.isSuccess(response) else {
            throw TeamServiceError.requestFailed(
                HTTPResponseValidator.localizedErrorMessage(from: data, fallback: fallback)
            )
        }
    }
}
