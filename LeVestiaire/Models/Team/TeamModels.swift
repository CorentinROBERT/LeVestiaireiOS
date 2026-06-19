//
//  TeamModels.swift
//  LeVestaire
//

import Foundation

enum TeamRole: String, Codable, CaseIterable, Identifiable {
    case admin
    case manager
    case player

    var id: String { rawValue }

    var canManageTeam: Bool {
        self == .admin || self == .manager
    }

    var canDeleteTeam: Bool {
        self == .admin
    }

    var canTransferAdmin: Bool {
        self == .admin
    }

    var canManageMembers: Bool {
        canManageTeam
    }

    var localizedLabel: String {
        switch self {
        case .admin:
            return L10n.text("admin")
        case .manager:
            return L10n.text("manager")
        case .player:
            return L10n.text("player")
        }
    }
}

struct SquadTeam: Identifiable, Decodable, Equatable {
    let id: String
    let name: String
    let description: String?
    let logoUrl: String?
    let adminId: String?
    let managerIds: [String]?
    let members: [TeamMember]?
    let memberCount: Int?
    let currentUserRole: TeamRole?
    let invitationCode: String?
    let invitationExpiryDate: String?
    let sport: String?
    let league: String?
    let isActive: Bool?
    let createdAt: String?
    let updatedAt: String?

    var resolvedMemberCount: Int {
        if let memberCount, memberCount > 0 {
            return memberCount
        }
        return members?.count ?? 0
    }

    var resolvedMembers: [TeamMember] {
        members ?? []
    }

    init(
        id: String,
        name: String,
        description: String? = nil,
        logoUrl: String? = nil,
        adminId: String? = nil,
        managerIds: [String]? = nil,
        members: [TeamMember]? = nil,
        memberCount: Int? = nil,
        currentUserRole: TeamRole? = nil,
        invitationCode: String? = nil,
        invitationExpiryDate: String? = nil,
        sport: String? = nil,
        league: String? = nil,
        isActive: Bool? = nil,
        createdAt: String? = nil,
        updatedAt: String? = nil
    ) {
        self.id = id
        self.name = name
        self.description = description
        self.logoUrl = logoUrl
        self.adminId = adminId
        self.managerIds = managerIds
        self.members = members
        self.memberCount = memberCount
        self.currentUserRole = currentUserRole
        self.invitationCode = invitationCode
        self.invitationExpiryDate = invitationExpiryDate
        self.sport = sport
        self.league = league
        self.isActive = isActive
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        id = try TeamDecoding.decodeId(from: container)
        name = try container.decodeIfPresent(String.self, forKey: .name)
            ?? container.decodeIfPresent(String.self, forKey: .teamName)
            ?? ""
        description = try container.decodeIfPresent(String.self, forKey: .description)
        logoUrl = try container.decodeIfPresent(String.self, forKey: .logoUrl)
            ?? container.decodeIfPresent(String.self, forKey: .logo)
            ?? container.decodeIfPresent(String.self, forKey: .teamLogo)
        adminId = try container.decodeIfPresent(String.self, forKey: .adminId)
        managerIds = try container.decodeIfPresent([String].self, forKey: .managerIds)
        members = try container.decodeIfPresent([TeamMember].self, forKey: .members)
        memberCount = TeamDecoding.decodeInt(from: container, forKey: .memberCount)
        currentUserRole = TeamRole.decode(from: container, forKey: .currentUserRole)
            ?? TeamRole.decode(from: container, forKey: .role)
            ?? TeamRole.decode(from: container, forKey: .userRole)
        invitationCode = try container.decodeIfPresent(String.self, forKey: .invitationCode)
        invitationExpiryDate = try container.decodeIfPresent(String.self, forKey: .invitationExpiryDate)
        sport = try container.decodeIfPresent(String.self, forKey: .sport)
        league = try container.decodeIfPresent(String.self, forKey: .league)
        isActive = try container.decodeIfPresent(Bool.self, forKey: .isActive)
        createdAt = try container.decodeIfPresent(String.self, forKey: .createdAt)
        updatedAt = try container.decodeIfPresent(String.self, forKey: .updatedAt)
    }

    private enum CodingKeys: String, CodingKey {
        case mongoId = "_id"
        case id
        case name
        case teamName
        case description
        case logoUrl
        case logo
        case teamLogo
        case adminId
        case managerIds
        case members
        case memberCount
        case currentUserRole
        case role
        case userRole
        case invitationCode
        case invitationExpiryDate
        case sport
        case league
        case isActive
        case createdAt
        case updatedAt
    }
}

struct TeamMember: Identifiable, Decodable, Equatable {
    let id: String
    let userId: String?
    let teamId: String?
    let firstName: String?
    let lastName: String?
    let email: String?
    let role: TeamRole?
    let jerseyNumber: Int?
    let position: String?
    let joinedAt: String?
    let isActive: Bool?
    let isGuest: Bool

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

    var initials: String {
        let first = firstName?.first.map(String.init) ?? ""
        let last = lastName?.first.map(String.init) ?? ""
        let value = (first + last).uppercased()
        return value.isEmpty ? "?" : value
    }

    init(
        id: String,
        userId: String? = nil,
        teamId: String? = nil,
        firstName: String? = nil,
        lastName: String? = nil,
        email: String? = nil,
        role: TeamRole? = nil,
        jerseyNumber: Int? = nil,
        position: String? = nil,
        joinedAt: String? = nil,
        isActive: Bool? = nil,
        isGuest: Bool = false
    ) {
        self.id = id
        self.userId = userId
        self.teamId = teamId
        self.firstName = firstName
        self.lastName = lastName
        self.email = email
        self.role = role
        self.jerseyNumber = jerseyNumber
        self.position = position
        self.joinedAt = joinedAt
        self.isActive = isActive
        self.isGuest = isGuest
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        id = try TeamDecoding.decodeId(from: container)
        let decodedUserId = try container.decodeIfPresent(String.self, forKey: .userId)
        let decodedEmail = try container.decodeIfPresent(String.self, forKey: .email)
        teamId = try container.decodeIfPresent(String.self, forKey: .teamId)

        if let user = try container.decodeIfPresent(TeamMemberUser.self, forKey: .user) {
            firstName = user.firstName
            lastName = user.lastName
            userId = decodedUserId ?? user.id
            email = decodedEmail ?? user.email
        } else {
            firstName = try container.decodeIfPresent(String.self, forKey: .firstName)
            lastName = try container.decodeIfPresent(String.self, forKey: .lastName)
            userId = decodedUserId
            email = decodedEmail
        }

        role = TeamRole.decode(from: container, forKey: .role)
        jerseyNumber = TeamDecoding.decodeInt(from: container, forKey: .jerseyNumber)
            ?? TeamDecoding.decodeInt(from: container, forKey: .number)
        position = try container.decodeIfPresent(String.self, forKey: .position)
        joinedAt = try container.decodeIfPresent(String.self, forKey: .joinedAt)
        isActive = try container.decodeIfPresent(Bool.self, forKey: .isActive)
        isGuest = (try? container.decodeIfPresent(Bool.self, forKey: .isGuest)) ?? false
    }

    private enum CodingKeys: String, CodingKey {
        case mongoId = "_id"
        case id
        case userId
        case teamId
        case firstName
        case lastName
        case email
        case role
        case jerseyNumber
        case number
        case position
        case joinedAt
        case isActive
        case isGuest
        case user
    }

    private struct TeamMemberUser: Decodable {
        let id: String?
        let firstName: String?
        let lastName: String?
        let email: String?
    }
}

struct TeamGuest: Identifiable, Decodable, Equatable {
    let id: String
    let firstName: String?
    let lastName: String?
    let email: String?
    let jerseyNumber: Int?
    let notes: String?

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
        return L10n.text("guestLabel")
    }
}

enum TeamGuestDecoding {
    static func decodeList(from data: Data) throws -> [TeamGuest] {
        if let guests = try? APIResponseDecoder.decodePayload([TeamGuest].self, from: data) {
            return guests
        }

        struct GuestsPayload: Decodable {
            let guests: [TeamGuest]?
        }

        if let payload = try? APIResponseDecoder.decodePayload(GuestsPayload.self, from: data),
           let guests = payload.guests {
            return guests
        }

        return try APIResponseDecoder.decode([TeamGuest].self, from: data)
    }
}

struct CreateTeamRequest: Encodable {
    let name: String
    let description: String?
    let userId: String
}

struct UpdateTeamRequest: Encodable {
    let name: String?
    let description: String?
}

struct InvitePlayerRequest: Encodable {
    let email: String
    let firstName: String?
    let lastName: String?
}

struct CreateGuestRequest: Encodable {
    let firstName: String
    let lastName: String?
    let email: String?
    let jerseyNumber: Int?
    let notes: String?
}

struct UpdateMemberRoleRequest: Encodable {
    let role: String
}

struct TeamMutationResponse: Decodable {
    let success: Bool?
    let message: String?
    let error: String?
    let data: SquadTeam?
}

struct TeamListPayload: Decodable {
    let teams: [SquadTeam]?
    let adminTeams: Int?
    let memberTeams: Int?
    let total: Int?
}

struct MyTeamsResponse: Decodable {
    let success: Bool?
    let data: TeamListPayload?

    var teams: [SquadTeam] {
        data?.teams ?? []
    }

    var adminTeamsCount: Int {
        data?.adminTeams ?? 0
    }

    var memberTeamsCount: Int {
        data?.memberTeams ?? 0
    }

    var totalTeams: Int {
        data?.total ?? teams.count
    }
}

struct RankingPlayerEntry: Identifiable, Decodable, Equatable {
    let id: String
    let firstName: String?
    let lastName: String?
    let goals: Int
    let assists: Int
    let points: Int

    var displayName: String {
        [firstName, lastName]
            .compactMap { $0 }
            .filter { !$0.isEmpty }
            .joined(separator: " ")
    }

    var scoreValue: Int {
        if points > 0 { return points }
        if goals > 0, assists == 0 { return goals }
        if assists > 0, goals == 0 { return assists }
        return goals + assists
    }

    init(
        id: String,
        firstName: String? = nil,
        lastName: String? = nil,
        goals: Int = 0,
        assists: Int = 0,
        points: Int = 0
    ) {
        self.id = id
        self.firstName = firstName
        self.lastName = lastName
        self.goals = goals
        self.assists = assists
        self.points = points
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decodeIfPresent(String.self, forKey: .userId)
            ?? (try? TeamDecoding.decodeId(from: container))
            ?? ""
        firstName = try container.decodeIfPresent(String.self, forKey: .firstName)
        lastName = try container.decodeIfPresent(String.self, forKey: .lastName)
        let count = TeamDecoding.decodeInt(from: container, forKey: .count) ?? 0
        goals = TeamDecoding.decodeInt(from: container, forKey: .goals)
            ?? TeamDecoding.decodeInt(from: container, forKey: .value)
            ?? count
        assists = TeamDecoding.decodeInt(from: container, forKey: .assists) ?? 0
        points = TeamDecoding.decodeInt(from: container, forKey: .points)
            ?? TeamDecoding.decodeInt(from: container, forKey: .total)
            ?? 0
    }

    private enum CodingKeys: String, CodingKey {
        case mongoId = "_id"
        case id
        case userId
        case firstName
        case lastName
        case goals
        case assists
        case points
        case total
        case value
        case count
    }
}

struct TeamSeasonRankingsPayload: Decodable, Equatable {
    let teamId: String?
    let season: String?
    let rankings: TeamSeasonRankings

    init(
        teamId: String? = nil,
        season: String? = nil,
        rankings: TeamSeasonRankings
    ) {
        self.teamId = teamId
        self.season = season
        self.rankings = rankings
    }
}

private struct RankingEntryDTO: Decodable {
    let userId: String
    let firstName: String?
    let lastName: String?
    let count: Int?
    let goals: Int?
    let assists: Int?

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        userId = try container.decode(String.self, forKey: .userId)
        firstName = try container.decodeIfPresent(String.self, forKey: .firstName)
        lastName = try container.decodeIfPresent(String.self, forKey: .lastName)
        count = TeamDecoding.decodeInt(from: container, forKey: .count)
        goals = TeamDecoding.decodeInt(from: container, forKey: .goals)
        assists = TeamDecoding.decodeInt(from: container, forKey: .assists)
    }

    func asScorer() -> RankingPlayerEntry {
        RankingPlayerEntry(
            id: userId,
            firstName: firstName,
            lastName: lastName,
            goals: count ?? goals ?? 0
        )
    }

    func asAssister() -> RankingPlayerEntry {
        RankingPlayerEntry(
            id: userId,
            firstName: firstName,
            lastName: lastName,
            assists: count ?? assists ?? 0
        )
    }

    func asTotal() -> RankingPlayerEntry {
        RankingPlayerEntry(
            id: userId,
            firstName: firstName,
            lastName: lastName,
            goals: goals ?? 0,
            assists: assists ?? 0,
            points: count ?? 0
        )
    }

    private enum CodingKeys: String, CodingKey {
        case userId
        case firstName
        case lastName
        case count
        case goals
        case assists
    }
}

struct TeamSeasonRankings: Decodable, Equatable {
    let scorers: [RankingPlayerEntry]
    let assisters: [RankingPlayerEntry]
    let general: [RankingPlayerEntry]

    init(
        scorers: [RankingPlayerEntry] = [],
        assisters: [RankingPlayerEntry] = [],
        general: [RankingPlayerEntry] = []
    ) {
        self.scorers = scorers
        self.assisters = assisters
        self.general = general
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        if let scorerDTOs = try? container.decode([RankingEntryDTO].self, forKey: .scorers) {
            scorers = scorerDTOs.map { $0.asScorer() }
        } else {
            scorers = try container.decodeIfPresent([RankingPlayerEntry].self, forKey: .scorers)
                ?? container.decodeIfPresent([RankingPlayerEntry].self, forKey: .topScorers)
                ?? []
        }

        if let assistDTOs = try? container.decode([RankingEntryDTO].self, forKey: .assists) {
            assisters = assistDTOs.map { $0.asAssister() }
        } else {
            assisters = try container.decodeIfPresent([RankingPlayerEntry].self, forKey: .assisters)
                ?? container.decodeIfPresent([RankingPlayerEntry].self, forKey: .assists)
                ?? container.decodeIfPresent([RankingPlayerEntry].self, forKey: .topAssisters)
                ?? []
        }

        if let totalDTOs = try? container.decode([RankingEntryDTO].self, forKey: .total) {
            general = totalDTOs.map { $0.asTotal() }
        } else {
            general = try container.decodeIfPresent([RankingPlayerEntry].self, forKey: .general)
                ?? container.decodeIfPresent([RankingPlayerEntry].self, forKey: .overall)
                ?? []
        }
    }

    private enum CodingKeys: String, CodingKey {
        case scorers
        case topScorers
        case assists
        case assisters
        case topAssisters
        case total
        case general
        case overall
    }
}

enum TeamRankingKind: String, CaseIterable, Identifiable {
    case scorers
    case assisters
    case general

    var id: String { rawValue }

    var title: String {
        switch self {
        case .scorers:
            return L10n.text("scorers")
        case .assisters:
            return L10n.text("assistProvider")
        case .general:
            return L10n.text("generalStatistics")
        }
    }
}

enum TeamDecoding {
    static func decodeMyTeams(from data: Data) throws -> MyTeamsResponse {
        if let response = try? APIResponseDecoder.decode(MyTeamsResponse.self, from: data) {
            return response
        }

        if let payload = try? APIResponseDecoder.decodePayload(TeamListPayload.self, from: data) {
            return MyTeamsResponse(success: true, data: payload)
        }

        let teams = try decodeTeams(from: data)
        return MyTeamsResponse(
            success: true,
            data: TeamListPayload(
                teams: teams,
                adminTeams: nil,
                memberTeams: nil,
                total: teams.count
            )
        )
    }

    static func decodeTeams(from data: Data) throws -> [SquadTeam] {
        if let response = try? decodeMyTeams(from: data) {
            return response.teams
        }

        if let teams = try? APIResponseDecoder.decodePayload([SquadTeam].self, from: data) {
            return teams
        }

        if let payload = try? APIResponseDecoder.decodePayload(TeamListPayload.self, from: data),
           let teams = payload.teams {
            return teams
        }

        if let teams = try? APIResponseDecoder.decode([SquadTeam].self, from: data) {
            return teams
        }

        if let payload = try? APIResponseDecoder.decode(TeamListPayload.self, from: data),
           let teams = payload.teams {
            return teams
        }

        throw DecodingError.dataCorrupted(
            DecodingError.Context(codingPath: [], debugDescription: "Unable to decode teams")
        )
    }

    static func decodeTeam(from data: Data) throws -> SquadTeam {
        if let team = try? APIResponseDecoder.decodePayload(SquadTeam.self, from: data) {
            return team
        }
        return try APIResponseDecoder.decode(SquadTeam.self, from: data)
    }

    static func decodeId<K: CodingKey>(from container: KeyedDecodingContainer<K>) throws -> String {
        if let mongoKey = K(stringValue: "_id"),
           let value = try container.decodeIfPresent(String.self, forKey: mongoKey) {
            return value
        }

        if let idKey = K(stringValue: "id") {
            if let value = try container.decodeIfPresent(String.self, forKey: idKey) {
                return value
            }
            if let value = try container.decodeIfPresent(Int.self, forKey: idKey) {
                return String(value)
            }
        }

        throw DecodingError.dataCorrupted(
            DecodingError.Context(
                codingPath: container.codingPath,
                debugDescription: "Missing id or _id"
            )
        )
    }

    static func decodeInt<K: CodingKey>(
        from container: KeyedDecodingContainer<K>,
        forKey key: K
    ) -> Int? {
        if let value = try? container.decodeIfPresent(Int.self, forKey: key) {
            return value
        }
        if let value = try? container.decodeIfPresent(Double.self, forKey: key) {
            return Int(value)
        }
        if let value = try? container.decodeIfPresent(String.self, forKey: key),
           let intValue = Int(value) {
            return intValue
        }
        return nil
    }
}

private extension TeamRole {
    static func decode<K: CodingKey>(
        from container: KeyedDecodingContainer<K>,
        forKey key: K
    ) -> TeamRole? {
        if let value = try? container.decodeIfPresent(String.self, forKey: key) {
            return TeamRole(rawValue: value.lowercased())
        }
        return nil
    }
}
