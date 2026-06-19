//
//  TeamInvitationModels.swift
//  LeVestaire
//

import Foundation

enum TeamInvitationStatus: String, Decodable, Equatable {
    case pending
    case accepted
    case declined
    case expired
    case cancelled
    case unknown

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let raw = (try? container.decode(String.self))?.lowercased() ?? ""
        self = TeamInvitationStatus(rawValue: raw) ?? .unknown
    }

    var localizedLabel: String {
        switch self {
        case .pending:
            return L10n.text("pending")
        case .accepted:
            return L10n.text("invitationAccepted")
        case .declined:
            return L10n.text("invitationDeclined")
        case .expired:
            return L10n.text("invitationExpiredStatus")
        case .cancelled:
            return L10n.text("cancelled")
        case .unknown:
            return L10n.text("pending")
        }
    }

    var canManage: Bool {
        self == .pending
    }
}

struct TeamInvitation: Identifiable, Decodable, Equatable {
    let id: String
    let email: String?
    let firstName: String?
    let lastName: String?
    let status: TeamInvitationStatus
    let createdAt: String?
    let expiresAt: String?

    var displayName: String {
        let parts = [firstName, lastName]
            .compactMap { $0?.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
        if !parts.isEmpty {
            return parts.joined(separator: " ")
        }
        if let email, !email.isEmpty {
            return email
        }
        return L10n.text("user")
    }

    var subtitle: String {
        if let email, !email.isEmpty, displayName != email {
            return email
        }
        return ""
    }

    init(
        id: String,
        email: String? = nil,
        firstName: String? = nil,
        lastName: String? = nil,
        status: TeamInvitationStatus = .pending,
        createdAt: String? = nil,
        expiresAt: String? = nil
    ) {
        self.id = id
        self.email = email
        self.firstName = firstName
        self.lastName = lastName
        self.status = status
        self.createdAt = createdAt
        self.expiresAt = expiresAt
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try TeamDecoding.decodeId(from: container)
        email = try container.decodeIfPresent(String.self, forKey: .email)
        firstName = try container.decodeIfPresent(String.self, forKey: .firstName)
        lastName = try container.decodeIfPresent(String.self, forKey: .lastName)
        status = (try? container.decode(TeamInvitationStatus.self, forKey: .status)) ?? .unknown
        createdAt = try container.decodeIfPresent(String.self, forKey: .createdAt)
        expiresAt = try container.decodeIfPresent(String.self, forKey: .expiresAt)
            ?? container.decodeIfPresent(String.self, forKey: .expiryDate)
    }

    private enum CodingKeys: String, CodingKey {
        case mongoId = "_id"
        case id
        case email
        case firstName
        case lastName
        case status
        case createdAt
        case expiresAt
        case expiryDate
    }
}

enum TeamInvitationDecoding {
    static func decodeList(from data: Data) throws -> [TeamInvitation] {
        if let invitations = try? APIResponseDecoder.decodePayload([TeamInvitation].self, from: data) {
            return invitations
        }

        struct InvitationsPayload: Decodable {
            let invitations: [TeamInvitation]?
        }

        if let payload = try? APIResponseDecoder.decodePayload(InvitationsPayload.self, from: data),
           let invitations = payload.invitations {
            return invitations
        }

        return try APIResponseDecoder.decode([TeamInvitation].self, from: data)
    }
}
