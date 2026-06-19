//
//  CompositionModels.swift
//  LeVestaire
//

import Foundation

struct TeamComposition: Identifiable, Decodable, Equatable {
    let id: String
    let name: String
    let formation: String?
    let tacticalNotes: String?
    let teamId: String?
    let matchId: String?
    /// Verrouillage lié à un match en cours (création / démarrage), pas à l’édition depuis l’équipe.
    let isLocked: Bool?
    let isActive: Bool?
    let starters: [CompositionAssignment]
    let substitutes: [CompositionAssignment]
    let alternatives: [CompositionAlternative]

    var resolvedStarters: [CompositionAssignment] { starters }
    var resolvedSubstitutes: [CompositionAssignment] { substitutes }
    var resolvedAlternatives: [CompositionAlternative] { alternatives }
    var alternativeCount: Int { resolvedAlternatives.count }
    var hasAlternativeFormations: Bool { alternativeCount > 0 }

    init(
        id: String,
        name: String,
        formation: String? = nil,
        tacticalNotes: String? = nil,
        teamId: String? = nil,
        matchId: String? = nil,
        isLocked: Bool? = nil,
        isActive: Bool? = nil,
        starters: [CompositionAssignment] = [],
        substitutes: [CompositionAssignment] = [],
        alternatives: [CompositionAlternative] = []
    ) {
        self.id = id
        self.name = name
        self.formation = formation
        self.tacticalNotes = tacticalNotes
        self.teamId = teamId
        self.matchId = matchId
        self.isLocked = isLocked
        self.isActive = isActive
        self.starters = starters
        self.substitutes = substitutes
        self.alternatives = alternatives
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        id = try TeamDecoding.decodeId(from: container)
        name = try container.decodeIfPresent(String.self, forKey: .name) ?? ""
        formation = try container.decodeIfPresent(String.self, forKey: .tactic)
            ?? container.decodeIfPresent(String.self, forKey: .formation)
        tacticalNotes = try container.decodeIfPresent(String.self, forKey: .description)
            ?? container.decodeIfPresent(String.self, forKey: .tacticalNotes)
        teamId = try container.decodeIfPresent(String.self, forKey: .teamId)
        matchId = try container.decodeIfPresent(String.self, forKey: .matchId)
        isLocked = try container.decodeIfPresent(Bool.self, forKey: .isLocked)
        isActive = try container.decodeIfPresent(Bool.self, forKey: .isActive)

        let positions = try container.decodeIfPresent(CompositionPositions.self, forKey: .positions)
        let parsed = CompositionPositionsParser.parse(
            positions: positions,
            tactic: formation ?? FormationCatalog.defaultFormationKey
        )
        starters = parsed.starters
        substitutes = parsed.substitutes

        alternatives = try container.decodeIfPresent([CompositionAlternative].self, forKey: .alternativeFormations)
            ?? container.decodeIfPresent([CompositionAlternative].self, forKey: .alternatives)
            ?? []
    }

    private enum CodingKeys: String, CodingKey {
        case mongoId = "_id"
        case id
        case name
        case tactic
        case formation
        case description
        case tacticalNotes
        case positions
        case alternativeFormations
        case alternatives
        case teamId
        case matchId
        case isLocked
        case isActive
    }
}

struct CompositionAlternative: Identifiable, Decodable, Equatable {
    let id: String
    let name: String
    let formation: String?
    let tacticalNotes: String?
    let starters: [CompositionAssignment]
    let substitutes: [CompositionAssignment]

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        if let alternativeId = try container.decodeIfPresent(String.self, forKey: .id) {
            id = alternativeId
        } else {
            id = try TeamDecoding.decodeId(from: container)
        }

        name = try container.decodeIfPresent(String.self, forKey: .name) ?? ""
        formation = try container.decodeIfPresent(String.self, forKey: .tactic)
            ?? container.decodeIfPresent(String.self, forKey: .formation)
        tacticalNotes = try container.decodeIfPresent(String.self, forKey: .description)
            ?? container.decodeIfPresent(String.self, forKey: .tacticalNotes)

        let positions = try container.decodeIfPresent(CompositionPositions.self, forKey: .positions)
        let parsed = CompositionPositionsParser.parse(
            positions: positions,
            tactic: formation ?? FormationCatalog.defaultFormationKey
        )
        starters = parsed.starters
        substitutes = parsed.substitutes
    }

    init(
        id: String,
        name: String,
        formation: String? = nil,
        tacticalNotes: String? = nil,
        starters: [CompositionAssignment] = [],
        substitutes: [CompositionAssignment] = []
    ) {
        self.id = id
        self.name = name
        self.formation = formation
        self.tacticalNotes = tacticalNotes
        self.starters = starters
        self.substitutes = substitutes
    }

    private enum CodingKeys: String, CodingKey {
        case mongoId = "_id"
        case id
        case name
        case tactic
        case formation
        case description
        case tacticalNotes
        case positions
    }
}

struct CompositionPositions: Decodable, Equatable {
    let goalkeeper: [CompositionPositionSlot]
    let defense: [CompositionPositionSlot]
    let midfield: [CompositionPositionSlot]
    let attack: [CompositionPositionSlot]
    let substitutes: [CompositionPositionSlot]

    init(
        goalkeeper: [CompositionPositionSlot] = [],
        defense: [CompositionPositionSlot] = [],
        midfield: [CompositionPositionSlot] = [],
        attack: [CompositionPositionSlot] = [],
        substitutes: [CompositionPositionSlot] = []
    ) {
        self.goalkeeper = goalkeeper
        self.defense = defense
        self.midfield = midfield
        self.attack = attack
        self.substitutes = substitutes
    }

    private enum CodingKeys: String, CodingKey {
        case goalkeeper = "Goalkeeper"
        case defense = "Defense"
        case midfield = "Midfield"
        case attack = "Attack"
        case substitutes
    }
}

struct CompositionPositionSlot: Decodable, Equatable {
    let user: CompositionPlayerUser?
    let guest: CompositionGuestRef?
    let position: CompositionPositionDetail?
    let isStarter: Bool?
    let jerseyNumber: Int?

    var resolvedUserId: String? {
        user?.id
    }

    var firstName: String? {
        user?.firstName ?? guest?.firstName
    }

    var lastName: String? {
        user?.lastName ?? guest?.lastName
    }

    var isSubstitute: Bool {
        isStarter == false
    }
}

struct CompositionPlayerUser: Decodable, Equatable {
    let id: String
    let email: String?
    let firstName: String?
    let lastName: String?
    let status: String?

    private enum CodingKeys: String, CodingKey {
        case mongoId = "_id"
        case id
        case email
        case firstName
        case lastName
        case status
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try TeamDecoding.decodeId(from: container)
        email = try container.decodeIfPresent(String.self, forKey: .email)
        firstName = try container.decodeIfPresent(String.self, forKey: .firstName)
        lastName = try container.decodeIfPresent(String.self, forKey: .lastName)
        status = try container.decodeIfPresent(String.self, forKey: .status)
    }
}

struct CompositionGuestRef: Decodable, Equatable {
    let id: String?
    let firstName: String?
    let lastName: String?

    private enum CodingKeys: String, CodingKey {
        case mongoId = "_id"
        case id
        case firstName
        case lastName
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try? TeamDecoding.decodeId(from: container)
        firstName = try container.decodeIfPresent(String.self, forKey: .firstName)
        lastName = try container.decodeIfPresent(String.self, forKey: .lastName)
    }
}

struct CompositionPositionDetail: Decodable, Equatable {
    let id: String?
    let name: String?
    let code: String?
    let category: String?
}

struct CompositionAssignment: Identifiable, Equatable {
    let id: String
    let position: String?
    let memberId: String?
    let playerId: String?
    let firstName: String?
    let lastName: String?
    let jerseyNumber: Int?
    let isStarter: Bool

    var resolvedMemberId: String? {
        memberId ?? playerId
    }

    var displayName: String {
        [firstName, lastName]
            .compactMap { $0 }
            .filter { !$0.isEmpty }
            .joined(separator: " ")
    }

    init(
        id: String? = nil,
        position: String? = nil,
        memberId: String? = nil,
        playerId: String? = nil,
        firstName: String? = nil,
        lastName: String? = nil,
        jerseyNumber: Int? = nil,
        isStarter: Bool = true
    ) {
        self.id = id ?? "\(position ?? "slot")-\(memberId ?? playerId ?? UUID().uuidString)"
        self.position = position
        self.memberId = memberId
        self.playerId = playerId
        self.firstName = firstName
        self.lastName = lastName
        self.jerseyNumber = jerseyNumber
        self.isStarter = isStarter
    }
}

enum CompositionPositionsParser {
    struct Parsed: Equatable {
        let starters: [CompositionAssignment]
        let substitutes: [CompositionAssignment]
        let starterAssignments: [String: String]
        let substituteMemberIds: [String?]
    }

    static func parse(positions: CompositionPositions?, tactic: String) -> Parsed {
        guard let positions else {
            return Parsed(
                starters: [],
                substitutes: [],
                starterAssignments: [:],
                substituteMemberIds: Array(repeating: nil, count: CompositionTabDraft.substituteCount)
            )
        }

        let template = FormationCatalog.template(for: tactic) ?? FormationCatalog.all[0]
        var assignments: [String: String] = [:]
        var starters: [CompositionAssignment] = []
        var substitutes: [CompositionAssignment] = []

        let categories: [(String, [CompositionPositionSlot])] = [
            ("Goalkeeper", positions.goalkeeper),
            ("Defense", positions.defense),
            ("Midfield", positions.midfield),
            ("Attack", positions.attack)
        ]

        for (category, slots) in categories {
            let slotIds = template.slotIds(forCategory: category)
            let starterSlots = slots.filter { $0.isStarter != false }

            for (index, slot) in starterSlots.enumerated() {
                guard index < slotIds.count, let userId = slot.resolvedUserId else { continue }
                let slotKey = slotIds[index]
                assignments[slotKey] = userId
                starters.append(
                    CompositionAssignment(
                        position: slotKey,
                        memberId: userId,
                        playerId: userId,
                        firstName: slot.firstName,
                        lastName: slot.lastName,
                        jerseyNumber: slot.jerseyNumber,
                        isStarter: true
                    )
                )
            }
        }

        for slot in positions.substitutes where slot.isSubstitute {
            guard let userId = slot.resolvedUserId else { continue }
            substitutes.append(
                CompositionAssignment(
                    position: slot.position?.code ?? "SUB",
                    memberId: userId,
                    playerId: userId,
                    firstName: slot.firstName,
                    lastName: slot.lastName,
                    jerseyNumber: slot.jerseyNumber,
                    isStarter: false
                )
            )
        }

        var substituteMemberIds = substitutes.compactMap(\.resolvedMemberId).map(Optional.some)
        while substituteMemberIds.count < CompositionTabDraft.substituteCount {
            substituteMemberIds.append(nil)
        }

        return Parsed(
            starters: starters,
            substitutes: substitutes,
            starterAssignments: assignments,
            substituteMemberIds: Array(substituteMemberIds.prefix(CompositionTabDraft.substituteCount))
        )
    }
}

struct CompositionSaveRequest: Encodable {
    let teamId: String
    let name: String
    let formation: String
    let tacticalNotes: String?
    let starters: [CompositionSlotRequest]
    let substitutes: [CompositionSlotRequest]
    let alternatives: [AlternativeCompositionRequest]?

    private enum CodingKeys: String, CodingKey {
        case teamId
        case name
        case tactic
        case description
        case starters
        case substitutes
        case alternatives = "alternativeFormations"
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(teamId, forKey: .teamId)
        try container.encode(name, forKey: .name)
        try container.encode(formation, forKey: .tactic)
        try container.encodeIfPresent(tacticalNotes, forKey: .description)
        try container.encode(starters, forKey: .starters)
        try container.encode(substitutes, forKey: .substitutes)
        try container.encodeIfPresent(alternatives, forKey: .alternatives)
    }
}

struct AlternativeCompositionRequest: Encodable {
    let id: String?
    let name: String
    let formation: String
    let tacticalNotes: String?
    let starters: [CompositionSlotRequest]
    let substitutes: [CompositionSlotRequest]

    private enum CodingKeys: String, CodingKey {
        case id
        case name
        case tactic
        case description
        case starters
        case substitutes
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encodeIfPresent(id, forKey: .id)
        try container.encode(name, forKey: .name)
        try container.encode(formation, forKey: .tactic)
        try container.encodeIfPresent(tacticalNotes, forKey: .description)
        try container.encode(starters, forKey: .starters)
        try container.encode(substitutes, forKey: .substitutes)
    }
}

struct CompositionSlotRequest: Encodable {
    let position: String
    let memberId: String
}

struct CompositionTabDraft: Identifiable, Equatable {
    let id: String
    var name: String
    var formationKey: String
    var starterAssignments: [String: String]
    var substituteMemberIds: [String?]
    var tacticalNotes: String
    var isMain: Bool
    var serverAlternativeId: String?

    static let substituteCount = 4

    init(
        id: String = UUID().uuidString,
        name: String = "",
        formationKey: String = FormationCatalog.defaultFormationKey,
        starterAssignments: [String: String] = [:],
        substituteMemberIds: [String?] = Array(repeating: nil, count: substituteCount),
        tacticalNotes: String = "",
        isMain: Bool = false,
        serverAlternativeId: String? = nil
    ) {
        self.id = id
        self.name = name
        self.formationKey = formationKey
        self.starterAssignments = starterAssignments
        self.substituteMemberIds = substituteMemberIds
        self.tacticalNotes = tacticalNotes
        self.isMain = isMain
        self.serverAlternativeId = serverAlternativeId
    }

    static func from(composition: TeamComposition) -> [CompositionTabDraft] {
        var tabs: [CompositionTabDraft] = [
            CompositionTabDraft(
                id: composition.id,
                name: composition.name,
                formationKey: composition.formation ?? FormationCatalog.defaultFormationKey,
                starterAssignments: assignmentsDictionary(from: composition.resolvedStarters),
                substituteMemberIds: substituteSlots(from: composition.resolvedSubstitutes),
                tacticalNotes: composition.tacticalNotes ?? "",
                isMain: true,
                serverAlternativeId: nil
            )
        ]

        for alternative in composition.resolvedAlternatives {
            tabs.append(
                CompositionTabDraft(
                    id: alternative.id,
                    name: alternative.name,
                    formationKey: alternative.formation ?? FormationCatalog.defaultFormationKey,
                    starterAssignments: assignmentsDictionary(from: alternative.starters),
                    substituteMemberIds: substituteSlots(from: alternative.substitutes),
                    tacticalNotes: alternative.tacticalNotes ?? "",
                    isMain: false,
                    serverAlternativeId: alternative.id
                )
            )
        }

        return tabs
    }

    func toSaveRequest(teamId: String, compositionId: String?) -> CompositionSaveRequest {
        CompositionSaveRequest(
            teamId: teamId,
            name: name,
            formation: formationKey,
            tacticalNotes: tacticalNotes.nilIfEmpty,
            starters: starterAssignments.map {
                CompositionSlotRequest(position: $0.key, memberId: $0.value)
            },
            substitutes: substituteMemberIds.compactMap { memberId in
                guard let memberId else { return nil }
                return CompositionSlotRequest(position: "SUB", memberId: memberId)
            },
            alternatives: nil
        )
    }

    private static func assignmentsDictionary(from starters: [CompositionAssignment]) -> [String: String] {
        var result: [String: String] = [:]
        for starter in starters {
            guard let position = starter.position,
                  let memberId = starter.resolvedMemberId else { continue }
            result[position] = memberId
        }
        return result
    }

    private static func substituteSlots(from substitutes: [CompositionAssignment]) -> [String?] {
        var slots: [String?] = substitutes.map(\.resolvedMemberId)
        while slots.count < substituteCount {
            slots.append(nil)
        }
        return Array(slots.prefix(substituteCount))
    }
}

private extension String {
    var nilIfEmpty: String? {
        let trimmed = trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }
}

enum CompositionDecoding {
    static func decodeCompositions(from data: Data) throws -> [TeamComposition] {
        if let response = try? APIResponseDecoder.decode(CompositionsListResponse.self, from: data),
           let compositions = response.data, !compositions.isEmpty {
            return compositions
        }

        if let compositions = try? APIResponseDecoder.decodePayload([TeamComposition].self, from: data),
           !compositions.isEmpty {
            return compositions
        }

        struct ListPayload: Decodable {
            let compositions: [TeamComposition]?
        }

        if let payload = try? APIResponseDecoder.decodePayload(ListPayload.self, from: data),
           let compositions = payload.compositions {
            return compositions
        }

        if let compositions = try? APIResponseDecoder.decode([TeamComposition].self, from: data) {
            return compositions
        }

        throw DecodingError.dataCorrupted(
            DecodingError.Context(codingPath: [], debugDescription: "Unable to decode compositions")
        )
    }

    static func decodeComposition(from data: Data) throws -> TeamComposition {
        if let composition = try? APIResponseDecoder.decodePayload(TeamComposition.self, from: data) {
            return composition
        }
        return try APIResponseDecoder.decode(TeamComposition.self, from: data)
    }
}

private struct CompositionsListResponse: Decodable {
    let success: Bool?
    let data: [TeamComposition]?
    let count: Int?
}
