//
//  CompositionModels.swift
//  LeVestaire
//

import Foundation

enum CompositionMemberKey {
    static let guestPrefix = "guest_"

    static func isGuestKey(_ key: String) -> Bool {
        key.hasPrefix(guestPrefix)
    }

    static func forGuest(_ rawId: String) -> String {
        guard !rawId.isEmpty else { return rawId }
        return rawId.hasPrefix(guestPrefix) ? rawId : "\(guestPrefix)\(rawId)"
    }

    static func rawGuestId(from key: String) -> String {
        isGuestKey(key) ? String(key.dropFirst(guestPrefix.count)) : key
    }

    static func variants(for key: String) -> Set<String> {
        guard !key.isEmpty else { return [] }
        var keys: Set<String> = [key]
        if isGuestKey(key) {
            keys.insert(rawGuestId(from: key))
        } else {
            keys.insert(forGuest(key))
        }
        return keys
    }
}

struct TeamComposition: Identifiable, Decodable, Equatable {
    let id: String
    let name: String
    let formation: String?
    let tacticalNotes: String?
    let teamId: String?
    let matchId: String?
    /// Obsolète — conservé pour rétrocompat API (`composition.isLocked`). Le verrou courant est `match.compositionLocked`.
    let isLocked: Bool?
    let isActive: Bool?
    let captainId: String?
    let starters: [CompositionAssignment]
    let substitutes: [CompositionAssignment]
    let alternatives: [CompositionAlternative]

    var resolvedStarters: [CompositionAssignment] { starters }
    var resolvedSubstitutes: [CompositionAssignment] { substitutes }
    var resolvedAlternatives: [CompositionAlternative] { alternatives }
    var alternativeCount: Int { resolvedAlternatives.count }
    var hasAlternativeFormations: Bool { alternativeCount > 0 }

    var allAssignments: [CompositionAssignment] {
        resolvedAlternatives.reduce(into: resolvedStarters + resolvedSubstitutes) { result, alternative in
            result.append(contentsOf: alternative.starters)
            result.append(contentsOf: alternative.substitutes)
        }
    }

    func enriched(from other: TeamComposition) -> TeamComposition {
        TeamComposition(
            id: id.isEmpty ? other.id : id,
            name: name.isEmpty ? other.name : name,
            formation: formation ?? other.formation,
            tacticalNotes: tacticalNotes ?? other.tacticalNotes,
            teamId: teamId ?? other.teamId,
            matchId: matchId ?? other.matchId,
            isLocked: isLocked,
            isActive: isActive ?? other.isActive,
            captainId: captainId ?? other.captainId,
            starters: starters.isEmpty ? other.starters : starters,
            substitutes: substitutes.isEmpty ? other.substitutes : substitutes,
            alternatives: alternatives.isEmpty ? other.alternatives : alternatives
        )
    }

    func enrichedWithTemplate(_ template: TeamComposition) -> TeamComposition {
        enriched(from: template)
    }

    init(
        id: String,
        name: String,
        formation: String? = nil,
        tacticalNotes: String? = nil,
        teamId: String? = nil,
        matchId: String? = nil,
        isLocked: Bool? = nil,
        isActive: Bool? = nil,
        captainId: String? = nil,
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
        self.captainId = captainId
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
        captainId = try container.decodeIfPresent(String.self, forKey: .captainId)

        let positions = try container.decodeIfPresent(CompositionPositions.self, forKey: .positions)
        let parsed = CompositionPositionsParser.parse(
            positions: positions,
            tactic: formation ?? FormationCatalog.defaultFormationKey
        )
        var resolvedStarters = parsed.starters
        var resolvedSubstitutes = parsed.substitutes

        if resolvedStarters.isEmpty {
            resolvedStarters = try container.decodeIfPresent([CompositionAssignment].self, forKey: .starters) ?? []
        }
        if resolvedSubstitutes.isEmpty {
            resolvedSubstitutes = try container.decodeIfPresent([CompositionAssignment].self, forKey: .substitutes) ?? []
        }

        starters = resolvedStarters
        substitutes = resolvedSubstitutes

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
        case starters
        case substitutes
        case teamId
        case matchId
        case isLocked
        case isActive
        case captainId
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
        var resolvedStarters = parsed.starters
        var resolvedSubstitutes = parsed.substitutes

        if resolvedStarters.isEmpty {
            resolvedStarters = try container.decodeIfPresent([CompositionAssignment].self, forKey: .starters) ?? []
        }
        if resolvedSubstitutes.isEmpty {
            resolvedSubstitutes = try container.decodeIfPresent([CompositionAssignment].self, forKey: .substitutes) ?? []
        }

        starters = resolvedStarters
        substitutes = resolvedSubstitutes
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
        case starters
        case substitutes
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

    var resolvedMemberId: String? {
        if let userId = user?.id {
            if user?.isGuest == true {
                return CompositionMemberKey.forGuest(userId)
            }
            return userId
        }
        if let guestId = guest?.id, !guestId.isEmpty {
            return CompositionMemberKey.forGuest(guestId)
        }
        return nil
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
    let isGuest: Bool?

    private enum CodingKeys: String, CodingKey {
        case mongoId = "_id"
        case id
        case email
        case firstName
        case lastName
        case status
        case isGuest
    }

    init(from decoder: Decoder) throws {
        if let singleValue = try? decoder.singleValueContainer(),
           let rawId = try? singleValue.decode(String.self),
           !rawId.isEmpty {
            let guest = CompositionMemberKey.isGuestKey(rawId)
            id = guest ? CompositionMemberKey.rawGuestId(from: rawId) : rawId
            email = nil
            firstName = nil
            lastName = nil
            status = guest ? "guest" : nil
            isGuest = guest
            return
        }

        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try TeamDecoding.decodeId(from: container)
        email = try container.decodeIfPresent(String.self, forKey: .email)
        firstName = try container.decodeIfPresent(String.self, forKey: .firstName)
        lastName = try container.decodeIfPresent(String.self, forKey: .lastName)
        status = try container.decodeIfPresent(String.self, forKey: .status)
        isGuest = try container.decodeIfPresent(Bool.self, forKey: .isGuest)
            ?? (status?.lowercased() == "guest")
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

struct CompositionAssignment: Identifiable, Equatable, Decodable {
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

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        position = try container.decodeIfPresent(String.self, forKey: .position)
        memberId = try container.decodeIfPresent(String.self, forKey: .memberId)
            ?? container.decodeIfPresent(String.self, forKey: .playerId)
        playerId = try container.decodeIfPresent(String.self, forKey: .playerId)
        firstName = try container.decodeIfPresent(String.self, forKey: .firstName)
        lastName = try container.decodeIfPresent(String.self, forKey: .lastName)
        jerseyNumber = try container.decodeIfPresent(Int.self, forKey: .jerseyNumber)
        isStarter = try container.decodeIfPresent(Bool.self, forKey: .isStarter) ?? true
        id = try container.decodeIfPresent(String.self, forKey: .id)
            ?? "\(position ?? "slot")-\(memberId ?? playerId ?? UUID().uuidString)"
    }

    private enum CodingKeys: String, CodingKey {
        case id
        case position
        case memberId
        case playerId
        case firstName
        case lastName
        case jerseyNumber
        case isStarter
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
                guard index < slotIds.count, let memberId = slot.resolvedMemberId else { continue }
                let slotKey = slotIds[index]
                assignments[slotKey] = memberId
                starters.append(
                    CompositionAssignment(
                        position: slotKey,
                        memberId: memberId,
                        playerId: memberId,
                        firstName: slot.firstName,
                        lastName: slot.lastName,
                        jerseyNumber: slot.jerseyNumber,
                        isStarter: true
                    )
                )
            }
        }

        for slot in positions.substitutes where slot.isStarter != true {
            guard let memberId = slot.resolvedMemberId else { continue }
            substitutes.append(
                CompositionAssignment(
                    position: slot.position?.code ?? "SUB",
                    memberId: memberId,
                    playerId: memberId,
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
    let teamId: String?
    let name: String
    let formation: String
    let tacticalNotes: String?
    let positions: CompositionPositionsSaveRequest
    let alternatives: [AlternativeCompositionRequest]?
    let captainId: String?
    let includeCaptainId: Bool
    let includeTeamId: Bool

    private enum CodingKeys: String, CodingKey {
        case teamId
        case name
        case tactic
        case description
        case positions
        case alternatives = "alternativeFormations"
        case captainId
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        if includeTeamId, let teamId {
            try container.encode(teamId, forKey: .teamId)
        }
        try container.encode(name, forKey: .name)
        try container.encode(formation, forKey: .tactic)
        try container.encodeIfPresent(tacticalNotes, forKey: .description)
        try container.encode(positions, forKey: .positions)
        try container.encodeIfPresent(alternatives, forKey: .alternatives)
        if includeCaptainId {
            if let captainId {
                try container.encode(captainId, forKey: .captainId)
            } else {
                try container.encodeNil(forKey: .captainId)
            }
        }
    }
}

struct CompositionCaptainPatchRequest: Encodable {
    let captainId: String?

    private enum CodingKeys: String, CodingKey {
        case captainId
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        if let captainId {
            try container.encode(captainId, forKey: .captainId)
        } else {
            try container.encodeNil(forKey: .captainId)
        }
    }
}

struct AlternativeCompositionRequest: Encodable {
    let id: String?
    let name: String
    let formation: String
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
        try container.encode(formation, forKey: .tactic)
        try container.encodeIfPresent(tacticalNotes, forKey: .description)
        try container.encode(positions, forKey: .positions)
    }
}

enum CompositionPositionCatalog {
    private static let referenceCreationDate = "2026-01-01T00:00:00.000Z"

    struct Definition {
        let id: String
        let name: String
        let code: String
        let category: String
        let displayOrder: Int
        let isAvailable: Bool
        let creationDate: String
    }

    static func definition(forSlotId slotId: String) -> Definition {
        switch slotId {
        case "GK":
            return Definition(
                id: "gk",
                name: "Goalkeeper",
                code: "GK",
                category: "Goalkeeper",
                displayOrder: 1,
                isAvailable: true,
                creationDate: referenceCreationDate
            )
        case let id where id.hasPrefix("D"):
            return Definition(
                id: "def_1",
                name: "Left Back",
                code: "DL",
                category: "Defense",
                displayOrder: 2,
                isAvailable: true,
                creationDate: referenceCreationDate
            )
        case let id where id.hasPrefix("M"):
            return Definition(
                id: "mid_1",
                name: "Defensive Midfielder",
                code: "MD",
                category: "Midfield",
                displayOrder: 5,
                isAvailable: true,
                creationDate: referenceCreationDate
            )
        case let id where id.hasPrefix("A"):
            return Definition(
                id: "att_1",
                name: "Forward",
                code: "ATT",
                category: "Attack",
                displayOrder: 7,
                isAvailable: true,
                creationDate: referenceCreationDate
            )
        default:
            return Definition(
                id: "def_1",
                name: "Left Back",
                code: "DL",
                category: "Defense",
                displayOrder: 2,
                isAvailable: true,
                creationDate: referenceCreationDate
            )
        }
    }
}

struct CompositionPositionMetaSaveRequest: Encodable {
    let id: String
    let name: String
    let code: String
    let category: String
    let isAvailable: Bool
    let displayOrder: Int
    let creationDate: String

    init(definition: CompositionPositionCatalog.Definition) {
        id = definition.id
        name = definition.name
        code = definition.code
        category = definition.category
        isAvailable = definition.isAvailable
        displayOrder = definition.displayOrder
        creationDate = definition.creationDate
    }
}

struct CompositionPlayerRefSaveRequest: Encodable {
    let id: String
    let firstName: String?
    let lastName: String?
    let email: String?

    init(id: String, firstName: String? = nil, lastName: String? = nil, email: String? = nil) {
        self.id = id
        self.firstName = firstName
        self.lastName = lastName
        self.email = email
    }

    private enum CodingKeys: String, CodingKey {
        case id = "_id"
        case firstName
        case lastName
        case email
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encodeIfPresent(firstName, forKey: .firstName)
        try container.encodeIfPresent(lastName, forKey: .lastName)
        try container.encodeIfPresent(email, forKey: .email)
    }
}

struct CompositionGuestRefSaveRequest: Encodable {
    let id: String
    let firstName: String?
    let lastName: String?

    init(id: String, firstName: String? = nil, lastName: String? = nil) {
        self.id = id
        self.firstName = firstName
        self.lastName = lastName
    }

    private enum CodingKeys: String, CodingKey {
        case id = "_id"
        case firstName
        case lastName
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encodeIfPresent(firstName, forKey: .firstName)
        try container.encodeIfPresent(lastName, forKey: .lastName)
    }
}

struct CompositionPositionSlotSaveRequest: Encodable {
    let user: CompositionPlayerRefSaveRequest?
    let guest: CompositionGuestRefSaveRequest?
    let position: CompositionPositionMetaSaveRequest
    let isStarter: Bool
    let jerseyNumber: Int?

    private enum CodingKeys: String, CodingKey {
        case user
        case guest
        case position
        case isStarter
        case jerseyNumber
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encodeIfPresent(user, forKey: .user)
        try container.encodeIfPresent(guest, forKey: .guest)
        try container.encode(position, forKey: .position)
        try container.encode(isStarter, forKey: .isStarter)
        try container.encodeIfPresent(jerseyNumber, forKey: .jerseyNumber)
    }

    static func make(
        memberId: String,
        slotId: String,
        isStarter: Bool,
        jerseyNumber: Int?,
        member: TeamMember? = nil
    ) -> CompositionPositionSlotSaveRequest {
        let position = CompositionPositionMetaSaveRequest(
            definition: CompositionPositionCatalog.definition(forSlotId: slotId)
        )

        if CompositionMemberKey.isGuestKey(memberId) {
            let rawGuestId = CompositionMemberKey.rawGuestId(from: memberId)
            return CompositionPositionSlotSaveRequest(
                user: nil,
                guest: CompositionGuestRefSaveRequest(
                    id: rawGuestId,
                    firstName: member?.firstName,
                    lastName: member?.lastName
                ),
                position: position,
                isStarter: isStarter,
                jerseyNumber: jerseyNumber
            )
        }

        return CompositionPositionSlotSaveRequest(
            user: CompositionPlayerRefSaveRequest(
                id: memberId,
                firstName: member?.firstName,
                lastName: member?.lastName,
                email: member?.email
            ),
            guest: nil,
            position: position,
            isStarter: isStarter,
            jerseyNumber: jerseyNumber
        )
    }
}

struct CompositionPositionsSaveRequest: Encodable {
    let goalkeeper: [CompositionPositionSlotSaveRequest]
    let defense: [CompositionPositionSlotSaveRequest]
    let midfield: [CompositionPositionSlotSaveRequest]
    let attack: [CompositionPositionSlotSaveRequest]
    let substitutes: [CompositionPositionSlotSaveRequest]

    private enum CodingKeys: String, CodingKey {
        case goalkeeper = "Goalkeeper"
        case defense = "Defense"
        case midfield = "Midfield"
        case attack = "Attack"
        case substitutes
    }

    static func from(tab: CompositionTabDraft, members: [TeamMember] = []) -> CompositionPositionsSaveRequest {
        let template = FormationCatalog.template(for: tab.formationKey) ?? FormationCatalog.all[0]

        func starterSlots(for category: String) -> [CompositionPositionSlotSaveRequest] {
            template.slotIds(forCategory: category).compactMap { slotId in
                guard let memberId = tab.starterAssignments[slotId] else { return nil }
                let member = members.first { $0.matchesCompositionMemberKey(memberId) }
                return CompositionPositionSlotSaveRequest.make(
                    memberId: memberId,
                    slotId: slotId,
                    isStarter: true,
                    jerseyNumber: CompositionJerseyResolver.resolve(
                        for: memberId,
                        members: members,
                        storedJerseyNumbers: tab.memberJerseyNumbers
                    ),
                    member: member
                )
            }
        }

        let substitutes = tab.substituteMemberIds.compactMap { memberId -> CompositionPositionSlotSaveRequest? in
            guard let memberId else { return nil }
            let member = members.first { $0.matchesCompositionMemberKey(memberId) }
            return CompositionPositionSlotSaveRequest.make(
                memberId: memberId,
                slotId: "SUB",
                isStarter: false,
                jerseyNumber: CompositionJerseyResolver.resolve(
                    for: memberId,
                    members: members,
                    storedJerseyNumbers: tab.memberJerseyNumbers
                ),
                member: member
            )
        }

        return CompositionPositionsSaveRequest(
            goalkeeper: starterSlots(for: "Goalkeeper"),
            defense: starterSlots(for: "Defense"),
            midfield: starterSlots(for: "Midfield"),
            attack: starterSlots(for: "Attack"),
            substitutes: substitutes
        )
    }
}

enum CompositionJerseyResolver {
    static func resolve(
        for memberId: String,
        members: [TeamMember],
        storedJerseyNumbers: [String: Int]
    ) -> Int? {
        for key in CompositionMemberKey.variants(for: memberId) {
            if let stored = storedJerseyNumbers[key] {
                return stored
            }
        }

        if let member = members.first(where: { $0.matchesCompositionMemberKey(memberId) }),
           let jerseyNumber = member.jerseyNumber {
            return jerseyNumber
        }

        return nil
    }
}

struct CompositionTabDraft: Identifiable, Equatable {
    let id: String
    var name: String
    var formationKey: String
    var starterAssignments: [String: String]
    var substituteMemberIds: [String?]
    var memberJerseyNumbers: [String: Int]
    var tacticalNotes: String
    var captainMemberKey: String?
    var isMain: Bool
    var serverAlternativeId: String?

    static let substituteCount = 4

    init(
        id: String = UUID().uuidString,
        name: String = "",
        formationKey: String = FormationCatalog.defaultFormationKey,
        starterAssignments: [String: String] = [:],
        substituteMemberIds: [String?] = Array(repeating: nil, count: substituteCount),
        memberJerseyNumbers: [String: Int] = [:],
        tacticalNotes: String = "",
        captainMemberKey: String? = nil,
        isMain: Bool = false,
        serverAlternativeId: String? = nil
    ) {
        self.id = id
        self.name = name
        self.formationKey = formationKey
        self.starterAssignments = starterAssignments
        self.substituteMemberIds = substituteMemberIds
        self.memberJerseyNumbers = memberJerseyNumbers
        self.tacticalNotes = tacticalNotes
        self.captainMemberKey = captainMemberKey
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
                memberJerseyNumbers: jerseyNumbersDictionary(
                    from: composition.resolvedStarters + composition.resolvedSubstitutes
                ),
                tacticalNotes: composition.tacticalNotes ?? "",
                captainMemberKey: composition.captainId,
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
                    memberJerseyNumbers: jerseyNumbersDictionary(
                        from: alternative.starters + alternative.substitutes
                    ),
                    tacticalNotes: alternative.tacticalNotes ?? "",
                    isMain: false,
                    serverAlternativeId: alternative.id
                )
            )
        }

        return tabs
    }

    func toSaveRequest(teamId: String, members: [TeamMember] = [], isUpdate: Bool = false) -> CompositionSaveRequest {
        teamSaveRequest(teamId: teamId, members: members, alternativeTabs: [], isUpdate: isUpdate)
    }

    var lineupMemberKeys: [String] {
        var keys = Array(starterAssignments.values)
        keys.append(contentsOf: substituteMemberIds.compactMap { $0 })
        return keys
    }

    func lineupMembers(from members: [TeamMember]) -> [TeamMember] {
        lineupMemberKeys.compactMap { key in
            members.first { $0.matchesCompositionMemberKey(key) }
        }
    }

    func sanitizedCaptainMemberKey() -> String? {
        guard let captainMemberKey else { return nil }
        let isInLineup = lineupMemberKeys.contains { key in
            CompositionMemberKey.variants(for: captainMemberKey).contains(key)
        }
        return isInLineup ? captainMemberKey : nil
    }

    func alternativeCompositionRequest(members: [TeamMember] = []) -> AlternativeCompositionRequest {
        AlternativeCompositionRequest(
            id: serverAlternativeId,
            name: name,
            formation: formationKey,
            tacticalNotes: tacticalNotes.nilIfEmpty,
            positions: CompositionPositionsSaveRequest.from(tab: self, members: members)
        )
    }

    func teamSaveRequest(
        teamId: String,
        members: [TeamMember] = [],
        alternativeTabs: [CompositionTabDraft],
        isUpdate: Bool = false
    ) -> CompositionSaveRequest {
        let alternatives = alternativeTabs.map { $0.alternativeCompositionRequest(members: members) }
        let captainId = isMain ? sanitizedCaptainMemberKey() : nil
        return CompositionSaveRequest(
            teamId: teamId,
            name: name,
            formation: formationKey,
            tacticalNotes: tacticalNotes.nilIfEmpty,
            positions: CompositionPositionsSaveRequest.from(tab: self, members: members),
            alternatives: alternatives.isEmpty ? nil : alternatives,
            captainId: captainId,
            includeCaptainId: isMain && (isUpdate || captainId != nil),
            includeTeamId: !isUpdate
        )
    }

    func matchSaveRequest(
        templateCompositionId: String?,
        members: [TeamMember],
        alternativeTabs: [CompositionTabDraft],
        isUpdate: Bool = false
    ) -> MatchCompositionSaveRequest {
        MatchCompositionSaveRequest.from(
            tab: self,
            templateCompositionId: templateCompositionId,
            members: members,
            alternativeTabs: alternativeTabs,
            isUpdate: isUpdate
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

    private static func jerseyNumbersDictionary(from assignments: [CompositionAssignment]) -> [String: Int] {
        var result: [String: Int] = [:]
        for assignment in assignments {
            guard let memberId = assignment.resolvedMemberId,
                  let jerseyNumber = assignment.jerseyNumber else { continue }
            result[memberId] = jerseyNumber
        }
        return result
    }
}

extension CompositionTabDraft {
    var displayLabel: String {
        if isMain {
            return L10n.text("compositionMain")
        }
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty {
            return L10n.text("alternativeFormations")
        }
        return trimmed
    }

    var formationDisplayName: String {
        FormationCatalog.template(for: formationKey)?.displayName ?? formationKey
    }

    var filledStarterCount: Int {
        starterAssignments.count
    }

    var filledSubstituteCount: Int {
        substituteMemberIds.compactMap { $0 }.count
    }
}

enum CompositionDisplayMemberResolver {
    static func members(
        for tab: CompositionTabDraft,
        in composition: TeamComposition,
        pool: [TeamMember]
    ) -> [TeamMember] {
        var resolved: [String: TeamMember] = [:]

        func store(_ member: TeamMember, for key: String) {
            guard !key.isEmpty else { return }
            resolved[key] = member
            for variant in CompositionMemberKey.variants(for: key) {
                resolved[variant] = member
            }
        }

        for member in pool {
            store(member, for: member.compositionMemberKey)
        }

        for assignment in composition.allAssignments {
            guard let memberId = assignment.resolvedMemberId else { continue }
            guard resolved[memberId] == nil else { continue }

            let isGuest = CompositionMemberKey.isGuestKey(memberId)
            let member = TeamMember(
                id: isGuest ? CompositionMemberKey.rawGuestId(from: memberId) : memberId,
                userId: isGuest ? nil : memberId,
                firstName: assignment.firstName,
                lastName: assignment.lastName,
                isGuest: isGuest
            )
            store(member, for: memberId)
        }

        let requiredKeys = tab.starterAssignments.values + tab.substituteMemberIds.compactMap { $0 }
        var ordered: [TeamMember] = []
        var seen = Set<String>()

        for key in requiredKeys {
            guard !seen.contains(key) else { continue }
            seen.insert(key)
            if let member = member(for: key, in: resolved) {
                ordered.append(member)
            }
        }

        for member in pool where !seen.contains(member.compositionMemberKey) {
            ordered.append(member)
        }

        return ordered
    }

    private static func member(for key: String, in resolved: [String: TeamMember]) -> TeamMember? {
        if let member = resolved[key] {
            return member
        }
        for variant in CompositionMemberKey.variants(for: key) {
            if let member = resolved[variant] {
                return member
            }
        }
        return nil
    }

    static func substituteEntries(
        for tab: CompositionTabDraft,
        in composition: TeamComposition,
        pool: [TeamMember]
    ) -> [CompositionSubstituteEntry] {
        let members = members(for: tab, in: composition, pool: pool)

        return tab.substituteMemberIds.compactMap { memberId in
            guard let memberId else { return nil }

            let member = members.first { $0.matchesCompositionMemberKey(memberId) }
            let assignment = composition.allAssignments.first { assignment in
                guard let assignmentId = assignment.resolvedMemberId else { return false }
                return CompositionMemberKey.variants(for: memberId).contains(assignmentId)
            }

            let displayName: String = {
                if let member, !member.displayName.isEmpty {
                    return member.displayName
                }
                if let assignment, !assignment.displayName.isEmpty {
                    return assignment.displayName
                }
                return memberId
            }()

            let fieldDisplayName: String = {
                if let member {
                    return member.fieldDisplayName
                }
                return TeamMember.fieldDisplayName(
                    firstName: assignment?.firstName,
                    lastName: assignment?.lastName,
                    fallback: displayName
                )
            }()

            return CompositionSubstituteEntry(
                id: memberId,
                initials: member?.initials ?? CompositionSubstituteEntry.initials(from: displayName),
                displayName: displayName,
                fieldDisplayName: fieldDisplayName
            )
        }
    }
}

struct CompositionSubstituteEntry: Identifiable, Equatable {
    let id: String
    let initials: String
    let displayName: String
    let fieldDisplayName: String

    static func initials(from name: String) -> String {
        let parts = name.split(separator: " ")
        let letters = parts.prefix(2).compactMap(\.first)
        let value = String(letters).uppercased()
        return value.isEmpty ? "?" : value
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
           let compositions = response.data {
            return compositions
        }

        if let compositions = try? APIResponseDecoder.decodePayload([TeamComposition].self, from: data) {
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
