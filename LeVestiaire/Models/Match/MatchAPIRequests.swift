//
//  MatchAPIRequests.swift
//  LeVestaire
//

import Foundation

// MARK: - Requests

struct CreateMatchRequest: Encodable {
    let opponentTeam: String
    let location: String
    let date: String
    let homeTeam: String
    let title: String?
    let description: String?
    let time: String
}

struct UpdateMatchRequest: Encodable {
    let opponentTeam: String?
    let location: String?
    let date: String?
    let title: String?
    let description: String?
    let time: String?
    let sendsTime: Bool

    init(
        opponentTeam: String?,
        location: String?,
        date: String?,
        title: String?,
        description: String?,
        time: String?,
        sendsTime: Bool = true
    ) {
        self.opponentTeam = opponentTeam
        self.location = location
        self.date = date
        self.title = title
        self.description = description
        self.time = time
        self.sendsTime = sendsTime
    }

    private enum CodingKeys: String, CodingKey {
        case opponentTeam
        case location
        case date
        case title
        case description
        case time
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encodeIfPresent(opponentTeam, forKey: .opponentTeam)
        try container.encodeIfPresent(location, forKey: .location)
        try container.encodeIfPresent(date, forKey: .date)
        try container.encodeIfPresent(title, forKey: .title)
        try container.encodeIfPresent(description, forKey: .description)

        if sendsTime {
            if let time {
                try container.encode(time, forKey: .time)
            } else {
                try container.encodeNil(forKey: .time)
            }
        }
    }
}

struct UpdateMyAvailabilityRequest: Encodable {
    let status: MatchAvailabilityStatus
}

struct ForcePlayerAvailabilityRequest: Encodable {
    let status: MatchAvailabilityStatus
}

struct MatchAlternativeCompositionSaveRequest: Encodable {
    let id: String?
    let name: String
    let formation: String?
    let tacticalNotes: String?
    let positions: CompositionPositionsSaveRequest

    private enum CodingKeys: String, CodingKey {
        case id
        case name
        case tactic
        case description
        case positions
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encodeIfPresent(id, forKey: .id)
        try container.encode(name, forKey: .name)
        try container.encodeIfPresent(formation, forKey: .tactic)
        try container.encodeIfPresent(tacticalNotes, forKey: .description)
        try container.encode(positions, forKey: .positions)
    }
}

struct MatchCompositionSaveRequest: Encodable {
    let templateCompositionId: String?
    let name: String
    let formation: String?
    let tacticalNotes: String?
    let positions: CompositionPositionsSaveRequest?
    let alternativeFormations: [MatchAlternativeCompositionSaveRequest]?

    private enum CodingKeys: String, CodingKey {
        case templateCompositionId
        case name
        case tactic
        case description
        case positions
        case alternativeFormations
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encodeIfPresent(templateCompositionId, forKey: .templateCompositionId)
        try container.encode(name, forKey: .name)
        try container.encodeIfPresent(formation, forKey: .tactic)
        try container.encodeIfPresent(tacticalNotes, forKey: .description)
        try container.encodeIfPresent(positions, forKey: .positions)
        try container.encodeIfPresent(alternativeFormations, forKey: .alternativeFormations)
    }

    static func from(
        tab: CompositionTabDraft,
        templateCompositionId: String? = nil,
        members: [TeamMember] = [],
        alternativeTabs: [CompositionTabDraft] = []
    ) -> MatchCompositionSaveRequest {
        MatchCompositionSaveRequest(
            templateCompositionId: templateCompositionId,
            name: tab.name,
            formation: tab.formationKey,
            tacticalNotes: tab.tacticalNotes.matchTrimmedOrNil,
            positions: CompositionPositionsSaveRequest.from(tab: tab, members: members),
            alternativeFormations: alternativeTabs.isEmpty
                ? nil
                : alternativeTabs.map { alternative in
                    MatchAlternativeCompositionSaveRequest(
                        id: alternative.serverAlternativeId,
                        name: alternative.name,
                        formation: alternative.formationKey,
                        tacticalNotes: alternative.tacticalNotes.matchTrimmedOrNil,
                        positions: CompositionPositionsSaveRequest.from(tab: alternative, members: members)
                    )
                }
        )
    }

    static func template(id: String, name: String) -> MatchCompositionSaveRequest {
        MatchCompositionSaveRequest(
            templateCompositionId: id,
            name: name,
            formation: nil,
            tacticalNotes: nil,
            positions: nil,
            alternativeFormations: nil
        )
    }
}

private extension String {
    var matchTrimmedOrNil: String? {
        let trimmed = trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }
}

extension MatchSelectablePlayer {
    func asTeamMember() -> TeamMember {
        let guest = isGuest ?? CompositionMemberKey.isGuestKey(id) || CompositionMemberKey.isGuestKey(userId ?? "")
        let rawId = CompositionMemberKey.rawGuestId(from: id.isEmpty ? (userId ?? "") : id)
        return TeamMember(
            id: rawId,
            userId: guest ? nil : (userId ?? rawId),
            firstName: firstName,
            lastName: lastName,
            isGuest: guest
        )
    }
}

struct UpdateMatchStatusRequest: Encodable {
    let status: MatchStatus
}

struct UpdateMatchScoreRequest: Encodable {
    let scoreHome: Int
    let scoreAway: Int
}

struct CreateMatchEventRequest: Encodable {
    let type: MatchEventType
    let minute: Int?
    let player: String?
    let comment: String?
}

struct UpdateMatchEventRequest: Encodable {
    let type: MatchEventType?
    let minute: Int?
    let player: String?
    let comment: String?
}
