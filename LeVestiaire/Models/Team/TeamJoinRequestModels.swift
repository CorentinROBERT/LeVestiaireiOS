//
//  TeamJoinRequestModels.swift
//  LeVestaire
//

import Foundation

enum TeamJoinRequestStatus: String, Decodable, Equatable, CaseIterable {
    case pending
    case approved
    case rejected
    case cancelled

    var localizedLabel: String {
        switch self {
        case .pending:
            return L10n.text("joinRequestStatusPending")
        case .approved:
            return L10n.text("joinRequestStatusApproved")
        case .rejected:
            return L10n.text("joinRequestStatusRejected")
        case .cancelled:
            return L10n.text("joinRequestStatusCancelled")
        }
    }
}

enum TeamJoinRequestReviewAction: String, Encodable {
    case approve
    case reject
}

struct TeamSearchResult: Decodable, Identifiable, Equatable {
    let id: String
    let name: String
    let memberCount: Int
    let createdAt: String?
    let sport: String?
    let league: String?
    let logoUrl: String?
    let isMember: Bool
    let hasPendingJoinRequest: Bool

    init(
        id: String,
        name: String,
        memberCount: Int = 0,
        createdAt: String? = nil,
        sport: String? = nil,
        league: String? = nil,
        logoUrl: String? = nil,
        isMember: Bool = false,
        hasPendingJoinRequest: Bool = false
    ) {
        self.id = id
        self.name = name
        self.memberCount = memberCount
        self.createdAt = createdAt
        self.sport = sport
        self.league = league
        self.logoUrl = logoUrl
        self.isMember = isMember
        self.hasPendingJoinRequest = hasPendingJoinRequest
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decodeIfPresent(String.self, forKey: .mongoId)
            ?? container.decodeIfPresent(String.self, forKey: .id)
            ?? ""
        name = try container.decodeIfPresent(String.self, forKey: .name) ?? ""
        memberCount = TeamDecoding.decodeInt(from: container, forKey: .memberCount) ?? 0
        createdAt = try container.decodeIfPresent(String.self, forKey: .createdAt)
        sport = try container.decodeIfPresent(String.self, forKey: .sport)
        league = try container.decodeIfPresent(String.self, forKey: .league)
        logoUrl = try container.decodeIfPresent(String.self, forKey: .logoUrl)
        isMember = try container.decodeIfPresent(Bool.self, forKey: .isMember) ?? false
        hasPendingJoinRequest = try container.decodeIfPresent(Bool.self, forKey: .hasPendingJoinRequest) ?? false
    }

    var subtitle: String {
        var parts: [String] = []
        if memberCount > 0 {
            parts.append(L10n.format("membersCount", memberCount))
        }
        if let sport, !sport.isEmpty {
            parts.append(sport)
        }
        if let league, !league.isEmpty {
            parts.append(league)
        }
        return parts.joined(separator: " · ")
    }

    private enum CodingKeys: String, CodingKey {
        case mongoId = "_id"
        case id
        case name
        case memberCount
        case createdAt
        case sport
        case league
        case logoUrl
        case isMember
        case hasPendingJoinRequest
    }
}

struct TeamJoinRequest: Decodable, Identifiable, Equatable {
    let id: String
    let teamId: String
    let teamName: String?
    let userId: String?
    let firstName: String?
    let lastName: String?
    let message: String?
    let status: TeamJoinRequestStatus
    let createdAt: String?
    let reviewedAt: String?

    var applicantDisplayName: String {
        let name = [firstName, lastName]
            .compactMap { $0?.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
            .joined(separator: " ")
        return name.isEmpty ? L10n.text("unknownPlayer") : name
    }

    var resolvedTeamName: String {
        let trimmed = teamName?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        return trimmed.isEmpty ? L10n.team : trimmed
    }

    init(
        id: String,
        teamId: String,
        teamName: String? = nil,
        userId: String? = nil,
        firstName: String? = nil,
        lastName: String? = nil,
        message: String? = nil,
        status: TeamJoinRequestStatus = .pending,
        createdAt: String? = nil,
        reviewedAt: String? = nil
    ) {
        self.id = id
        self.teamId = teamId
        self.teamName = teamName
        self.userId = userId
        self.firstName = firstName
        self.lastName = lastName
        self.message = message
        self.status = status
        self.createdAt = createdAt
        self.reviewedAt = reviewedAt
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decodeIfPresent(String.self, forKey: .mongoId)
            ?? container.decodeIfPresent(String.self, forKey: .id)
            ?? ""

        var decodedTeamId = try container.decodeIfPresent(String.self, forKey: .teamId) ?? ""
        var decodedTeamName = try container.decodeIfPresent(String.self, forKey: .teamName)

        if let nestedTeam = try? container.decodeIfPresent(JoinRequestTeam.self, forKey: .team) {
            if decodedTeamId.isEmpty, let teamId = nestedTeam.id, !teamId.isEmpty {
                decodedTeamId = teamId
            }
            if decodedTeamName?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty != false,
               let name = nestedTeam.name,
               !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                decodedTeamName = name
            }
        }

        teamId = decodedTeamId
        teamName = decodedTeamName

        if let nestedUser = try? container.decodeIfPresent(JoinRequestUser.self, forKey: .user) {
            userId = nestedUser.id
            firstName = nestedUser.firstName
            lastName = nestedUser.lastName
        } else {
            userId = try container.decodeIfPresent(String.self, forKey: .userId)
            firstName = try container.decodeIfPresent(String.self, forKey: .firstName)
            lastName = try container.decodeIfPresent(String.self, forKey: .lastName)
        }

        message = try container.decodeIfPresent(String.self, forKey: .message)
        status = try container.decodeIfPresent(TeamJoinRequestStatus.self, forKey: .status) ?? .pending
        createdAt = try container.decodeIfPresent(String.self, forKey: .createdAt)
        reviewedAt = try container.decodeIfPresent(String.self, forKey: .reviewedAt)
    }

    private enum CodingKeys: String, CodingKey {
        case mongoId = "_id"
        case id
        case teamId
        case teamName
        case team
        case user
        case userId
        case firstName
        case lastName
        case message
        case status
        case createdAt
        case reviewedAt
    }
}

private struct JoinRequestTeam: Decodable {
    let id: String?
    let name: String?

    enum CodingKeys: String, CodingKey {
        case mongoId = "_id"
        case id
        case name
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decodeIfPresent(String.self, forKey: .mongoId)
            ?? container.decodeIfPresent(String.self, forKey: .id)
        name = try container.decodeIfPresent(String.self, forKey: .name)
    }
}

private struct JoinRequestUser: Decodable {
    let id: String?
    let firstName: String?
    let lastName: String?

    enum CodingKeys: String, CodingKey {
        case mongoId = "_id"
        case id
        case firstName
        case lastName
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decodeIfPresent(String.self, forKey: .mongoId)
            ?? container.decodeIfPresent(String.self, forKey: .id)
        firstName = try container.decodeIfPresent(String.self, forKey: .firstName)
        lastName = try container.decodeIfPresent(String.self, forKey: .lastName)
    }
}

struct CreateTeamJoinRequest: Encodable {
    let message: String?
}

struct ReviewTeamJoinRequest: Encodable {
    let action: TeamJoinRequestReviewAction
}

enum TeamJoinRequestDecoding {
    static func decodeSearchResults(from data: Data) throws -> [TeamSearchResult] {
        if let results = try? APIResponseDecoder.decodePayload([TeamSearchResult].self, from: data) {
            return results.filter { !$0.id.isEmpty }
        }
        if let results = try? APIResponseDecoder.decode([TeamSearchResult].self, from: data) {
            return results.filter { !$0.id.isEmpty }
        }

        struct SearchPayload: Decodable {
            let teams: [TeamSearchResult]?
            let results: [TeamSearchResult]?
        }

        if let payload = try? APIResponseDecoder.decodePayload(SearchPayload.self, from: data) {
            return (payload.teams ?? payload.results ?? []).filter { !$0.id.isEmpty }
        }

        return []
    }

    static func decodeJoinRequests(from data: Data) throws -> [TeamJoinRequest] {
        if let requests = try? APIResponseDecoder.decodePayload([TeamJoinRequest].self, from: data) {
            return requests.filter { !$0.id.isEmpty }
        }
        if let requests = try? APIResponseDecoder.decode([TeamJoinRequest].self, from: data) {
            return requests.filter { !$0.id.isEmpty }
        }

        struct RequestsPayload: Decodable {
            let joinRequests: [TeamJoinRequest]?
            let requests: [TeamJoinRequest]?
        }

        if let payload = try? APIResponseDecoder.decodePayload(RequestsPayload.self, from: data) {
            return (payload.joinRequests ?? payload.requests ?? []).filter { !$0.id.isEmpty }
        }

        return []
    }

    static func decodeJoinRequest(from data: Data) throws -> TeamJoinRequest {
        if let request = try? APIResponseDecoder.decodePayload(TeamJoinRequest.self, from: data) {
            return request
        }
        return try APIResponseDecoder.decode(TeamJoinRequest.self, from: data)
    }
}
