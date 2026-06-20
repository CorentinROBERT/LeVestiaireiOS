//
//  MatchFlowModels.swift
//  LeVestaire
//

import Foundation

enum MatchSharedDecoding {
    private static let iso8601WithFractionalSeconds: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter
    }()

    private static let iso8601: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime]
        return formatter
    }()

    private static let dateOnlyFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }()

    static func parseDateString(_ value: String) -> Date? {
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }
        if let date = iso8601WithFractionalSeconds.date(from: trimmed) {
            return date
        }
        if let date = iso8601.date(from: trimmed) {
            return date
        }
        return dateOnlyFormatter.date(from: trimmed)
    }

    struct TeamReference: Decodable {
        let id: String?
        let mongoId: String?
        let name: String?

        enum CodingKeys: String, CodingKey {
            case id
            case mongoId = "_id"
            case name
        }

        var resolvedId: String? {
            mongoId ?? id
        }

        var resolvedName: String? {
            guard let rawName = name?.trimmingCharacters(in: .whitespacesAndNewlines),
                  !rawName.isEmpty else {
                return nil
            }
            return rawName
        }
    }

    static func resolveTeamId<K: CodingKey>(
        from container: KeyedDecodingContainer<K>,
        teamId: K,
        homeTeam: K,
        team: K
    ) -> String? {
        if let teamId = try? container.decodeIfPresent(String.self, forKey: teamId) {
            return teamId
        }
        if let homeTeam = try? container.decodeIfPresent(String.self, forKey: homeTeam) {
            return homeTeam
        }
        if let homeTeamRef = try? container.decodeIfPresent(TeamReference.self, forKey: homeTeam) {
            return homeTeamRef.resolvedId
        }
        if let team = try? container.decodeIfPresent(TeamReference.self, forKey: team) {
            return team.resolvedId
        }
        return nil
    }

    static func resolveTeamName<K: CodingKey>(
        from container: KeyedDecodingContainer<K>,
        homeTeamName: K,
        homeTeam: K,
        team: K
    ) -> String? {
        if let name = try? container.decodeIfPresent(String.self, forKey: homeTeamName)?
            .trimmingCharacters(in: .whitespacesAndNewlines),
           !name.isEmpty {
            return name
        }
        if let homeTeamRef = try? container.decodeIfPresent(TeamReference.self, forKey: homeTeam) {
            return homeTeamRef.resolvedName
        }
        if let teamRef = try? container.decodeIfPresent(TeamReference.self, forKey: team) {
            return teamRef.resolvedName
        }
        return nil
    }
}

// MARK: - UX modes & phases

enum MatchPreparationPhase: String, Codable, Hashable, CaseIterable {
    case collectingAvailability
    case buildingComposition
    case readyToPublish

    var displayName: String {
        switch self {
        case .collectingAvailability:
            return L10n.text("matchPhaseAvailability")
        case .buildingComposition:
            return L10n.text("matchPhaseCompositionCreation")
        case .readyToPublish:
            return L10n.text("matchPhaseReadyToStart")
        }
    }
}

enum MatchUXMode: Equatable {
    case respond
    case prepare
    case animate
    case readOnly
}

enum PublishBlocker: Hashable {
    case missingMinimalInfo
    case missingComposition
    case insufficientAvailabilityResponses
    case unknown(String)

    init(code: String) {
        switch code {
        case "MISSING_MINIMAL_INFO":
            self = .missingMinimalInfo
        case "MISSING_COMPOSITION":
            self = .missingComposition
        case "INSUFFICIENT_AVAILABILITY_RESPONSES":
            self = .insufficientAvailabilityResponses
        default:
            self = .unknown(code)
        }
    }

    var blocksPublication: Bool {
        if case .missingMinimalInfo = self { return true }
        return false
    }
}

extension PublishBlocker: Decodable {
    init(from decoder: Decoder) throws {
        let code = try decoder.singleValueContainer().decode(String.self)
        self.init(code: code)
    }
}

enum MatchAvailabilityStatus: String, Codable, CaseIterable, Hashable {
    case available
    case absent
    case unknown

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let raw = try container.decode(String.self).trimmingCharacters(in: .whitespacesAndNewlines).lowercased()

        switch raw {
        case "available", "present", "yes", "oui":
            self = .available
        case "absent", "no", "non":
            self = .absent
        case "unknown", "pending", "waiting":
            self = .unknown
        default:
            self = MatchAvailabilityStatus(rawValue: raw) ?? .unknown
        }
    }

    var displayName: String {
        switch self {
        case .available:
            return L10n.text("availabilityPresent")
        case .absent:
            return L10n.text("availabilityAbsent")
        case .unknown:
            return L10n.text("availabilityUnknown")
        }
    }
}

enum AvailabilitySource: String, Codable, Hashable {
    case selfDeclared = "self"
    case forcedByStaff

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let raw = try container.decode(String.self).trimmingCharacters(in: .whitespacesAndNewlines).lowercased()

        switch raw {
        case "self", "selfdeclared", "player", "user":
            self = .selfDeclared
        case "forcedbystaff", "staff", "admin", "manager", "forced":
            self = .forcedByStaff
        default:
            self = AvailabilitySource(rawValue: raw) ?? .selfDeclared
        }
    }
}

enum MatchAPIErrorCode: String {
    case availabilityClosed = "AVAILABILITY_CLOSED"
}

enum MatchEventType: String, Codable, CaseIterable, Hashable {
    case goal
    case ownGoal
    case opponentGoal
    case opponentOwnGoal
    case assist
    case yellowCard
    case redCard
    case substitution
    case matchStart
    case matchEnd
    case shotOnTarget
    case save
    case injury
    case manOfTheMatch
    case shlag
    case other

    static var userCreatableCases: [MatchEventType] {
        [.goal, .ownGoal, .opponentGoal, .opponentOwnGoal, .assist, .yellowCard, .redCard, .substitution]
    }

    var isSystemGenerated: Bool {
        switch self {
        case .matchStart, .matchEnd:
            return true
        default:
            return false
        }
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let rawValue = try container.decode(String.self)
        guard let resolved = Self.resolve(from: rawValue) else {
            throw DecodingError.dataCorruptedError(
                in: container,
                debugDescription: "Unsupported match event type: \(rawValue)"
            )
        }
        self = resolved
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(rawValue)
    }

    static func resolve(from rawValue: String) -> MatchEventType? {
        let normalized = rawValue
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()
            .replacingOccurrences(of: "-", with: "_")
            .replacingOccurrences(of: " ", with: "_")

        switch normalized {
        case "goal", "event_type_goal", "eventtypegoal":
            return .goal
        case "own_goal", "owngoal", "own_goal_event", "event_type_own_goal", "eventtypeowngoal":
            return .ownGoal
        case "opponent_goal", "opponentgoal", "event_type_opponent_goal":
            return .opponentGoal
        case "opponent_own_goal", "opponentowngoal", "event_type_opponent_own_goal":
            return .opponentOwnGoal
        case "assist", "event_type_assist", "eventtypeassist":
            return .assist
        case "yellow_card", "yellowcard", "event_type_yellow_card", "eventtypeyellowcard":
            return .yellowCard
        case "red_card", "redcard", "event_type_red_card", "eventtyperedcard":
            return .redCard
        case "substitution", "sub", "event_type_substitution", "eventtypesubstitution":
            return .substitution
        case "match_start", "matchstart", "kick_off", "kickoff", "start", "match_started", "matchstarted":
            return .matchStart
        case "match_end", "matchend", "match_finished", "matchfinished", "finish", "end", "full_time", "fulltime":
            return .matchEnd
        case "shot_on_target", "shotontarget", "event_type_shot_on_target":
            return .shotOnTarget
        case "save", "goalkeeper_save", "goalkeepersave", "event_type_save":
            return .save
        case "injury", "event_type_injury":
            return .injury
        case "man_of_the_match", "manofthematch", "motm", "event_type_man_of_the_match":
            return .manOfTheMatch
        case "shlag", "event_type_shlag":
            return .shlag
        default:
            if let match = MatchEventType(rawValue: rawValue) {
                return match
            }
            if let match = MatchEventType(rawValue: normalized.snakeCaseToLowerCamel()) {
                return match
            }
            return .other
        }
    }

    var displayName: String {
        switch self {
        case .goal:
            return L10n.text("goal")
        case .ownGoal:
            return L10n.text("ownGoalEvent")
        case .opponentGoal:
            return L10n.text("opponentGoal")
        case .opponentOwnGoal:
            return L10n.text("opponentOwnGoal")
        case .assist:
            return L10n.text("assist")
        case .yellowCard:
            return L10n.text("yellowCard")
        case .redCard:
            return L10n.text("redCard")
        case .substitution:
            return L10n.text("substitution")
        case .matchStart:
            return L10n.text("matchStart")
        case .matchEnd:
            return L10n.text("matchEnd")
        case .shotOnTarget:
            return L10n.text("shotOnTarget")
        case .save:
            return L10n.text("goalkeeperSave")
        case .injury:
            return L10n.text("injury")
        case .manOfTheMatch:
            return L10n.text("manOfTheMatch")
        case .shlag:
            return L10n.text("eventTypeShlag")
        case .other:
            return L10n.text("other")
        }
    }

    var requiresPlayer: Bool {
        switch self {
        case .opponentGoal, .opponentOwnGoal, .matchStart, .matchEnd, .other:
            return false
        default:
            return true
        }
    }
}

// MARK: - Capabilities

struct MatchCapabilities: Decodable, Equatable, Hashable {
    let canRespond: Bool
    let canManageAvailability: Bool
    let canManageComposition: Bool
    let canPublish: Bool
    let canStartMatch: Bool
    let canManageEvents: Bool
    let canUpdateScore: Bool
    let canFinishMatch: Bool

    static let empty = MatchCapabilities(
        canRespond: false,
        canManageAvailability: false,
        canManageComposition: false,
        canPublish: false,
        canStartMatch: false,
        canManageEvents: false,
        canUpdateScore: false,
        canFinishMatch: false
    )

    init(
        canRespond: Bool,
        canManageAvailability: Bool,
        canManageComposition: Bool,
        canPublish: Bool,
        canStartMatch: Bool,
        canManageEvents: Bool,
        canUpdateScore: Bool,
        canFinishMatch: Bool
    ) {
        self.canRespond = canRespond
        self.canManageAvailability = canManageAvailability
        self.canManageComposition = canManageComposition
        self.canPublish = canPublish
        self.canStartMatch = canStartMatch
        self.canManageEvents = canManageEvents
        self.canUpdateScore = canUpdateScore
        self.canFinishMatch = canFinishMatch
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        canRespond = try container.decodeIfPresent(Bool.self, forKey: .canRespond) ?? false
        canManageAvailability = try container.decodeIfPresent(Bool.self, forKey: .canManageAvailability) ?? false
        canManageComposition = try container.decodeIfPresent(Bool.self, forKey: .canManageComposition) ?? false
        canPublish = try container.decodeIfPresent(Bool.self, forKey: .canPublish) ?? false
        canStartMatch = try container.decodeIfPresent(Bool.self, forKey: .canStartMatch) ?? false
        canManageEvents = try container.decodeIfPresent(Bool.self, forKey: .canManageEvents) ?? false
        canUpdateScore = try container.decodeIfPresent(Bool.self, forKey: .canUpdateScore) ?? false
        canFinishMatch = try container.decodeIfPresent(Bool.self, forKey: .canFinishMatch) ?? false
    }

    func merged(with previous: MatchCapabilities) -> MatchCapabilities {
        MatchCapabilities(
            canRespond: canRespond || previous.canRespond,
            canManageAvailability: canManageAvailability || previous.canManageAvailability,
            canManageComposition: canManageComposition || previous.canManageComposition,
            canPublish: canPublish || previous.canPublish,
            canStartMatch: canStartMatch || previous.canStartMatch,
            canManageEvents: canManageEvents || previous.canManageEvents,
            canUpdateScore: canUpdateScore || previous.canUpdateScore,
            canFinishMatch: canFinishMatch || previous.canFinishMatch
        )
    }

    private enum CodingKeys: String, CodingKey {
        case canRespond
        case canManageAvailability
        case canManageComposition
        case canPublish
        case canStartMatch
        case canManageEvents
        case canUpdateScore
        case canFinishMatch
    }
}

struct AvailabilitySummary: Decodable, Equatable, Hashable {
    let respondedCount: Int
    let presentCount: Int
    let totalEligible: Int
    let totalMembers: Int
    let totalGuests: Int
    let absentCount: Int
    let unknownCount: Int
    let pendingCount: Int

    init(
        respondedCount: Int = 0,
        presentCount: Int = 0,
        totalEligible: Int = 0,
        totalMembers: Int = 0,
        totalGuests: Int = 0,
        absentCount: Int = 0,
        unknownCount: Int = 0,
        pendingCount: Int = 0
    ) {
        self.respondedCount = respondedCount
        self.presentCount = presentCount
        self.totalEligible = totalEligible
        self.totalMembers = totalMembers
        self.totalGuests = totalGuests
        self.absentCount = absentCount
        self.unknownCount = unknownCount
        self.pendingCount = pendingCount
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        respondedCount = try container.decodeIfPresent(Int.self, forKey: .respondedCount) ?? 0
        presentCount = try container.decodeIfPresent(Int.self, forKey: .presentCount) ?? 0
        totalMembers = try container.decodeIfPresent(Int.self, forKey: .totalMembers) ?? 0
        totalGuests = try container.decodeIfPresent(Int.self, forKey: .totalGuests) ?? 0
        absentCount = try container.decodeIfPresent(Int.self, forKey: .absentCount) ?? 0
        unknownCount = try container.decodeIfPresent(Int.self, forKey: .unknownCount) ?? 0
        pendingCount = try container.decodeIfPresent(Int.self, forKey: .pendingCount) ?? 0

        if let totalEligible = try container.decodeIfPresent(Int.self, forKey: .totalEligible) {
            self.totalEligible = totalEligible
        } else if totalMembers + totalGuests > 0 {
            self.totalEligible = totalMembers + totalGuests
        } else if totalMembers > 0 {
            self.totalEligible = totalMembers
        } else {
            self.totalEligible = 0
        }
    }

    private enum CodingKeys: String, CodingKey {
        case respondedCount
        case presentCount
        case totalEligible
        case totalMembers
        case totalGuests
        case absentCount
        case unknownCount
        case pendingCount
    }

    var responseRateText: String {
        "\(respondedCount)/\(totalEligible)"
    }
}

// MARK: - Match detail

struct MatchDetail: Decodable, Identifiable, Equatable {
    let id: String
    let title: String
    let status: MatchStatus
    let statusLabel: String?
    let preparationPhase: MatchPreparationPhase?
    let isPreparationLocked: Bool
    let isCompositionLocked: Bool
    let canPublish: Bool
    let publishBlockers: [PublishBlocker]
    let myAvailabilityStatus: MatchAvailabilityStatus?
    let availabilitySummary: AvailabilitySummary?
    let capabilities: MatchCapabilities
    let opponentTeam: String?
    let location: String?
    let homeTeamName: String?
    let teamId: String?
    let date: Date
    let startTime: String?
    let homeScore: Int?
    let awayScore: Int?
    let composition: TeamComposition?

    var uxMode: MatchUXMode {
        switch status {
        case .draft, .postponed:
            if capabilities.canManageAvailability || capabilities.canPublish || capabilities.canManageComposition {
                return .prepare
            }
            return capabilities.canRespond ? .respond : .readOnly
        case .ongoing:
            return capabilities.canManageEvents || capabilities.canFinishMatch ? .animate : .readOnly
        case .upcoming, .finished, .cancelled:
            return .readOnly
        }
    }

    var resolvedStatusLabel: String {
        statusLabel ?? status.displayName
    }

    var scoreText: String? {
        guard let homeScore, let awayScore else { return nil }
        return "\(homeScore) - \(awayScore)"
    }

    var blockingPublishBlockers: [PublishBlocker] {
        publishBlockers.filter(\.blocksPublication)
    }

    var warningPublishBlockers: [PublishBlocker] {
        publishBlockers.filter { !$0.blocksPublication }
    }

    func toMatchItem() -> MatchItem {
        MatchItem(
            id: id,
            title: title,
            status: status,
            statusLabel: statusLabel,
            preparationPhase: preparationPhase,
            isPreparationLocked: isPreparationLocked,
            isCompositionLocked: isCompositionLocked,
            canPublish: canPublish,
            publishBlockers: publishBlockers,
            myAvailabilityStatus: myAvailabilityStatus,
            availabilitySummary: availabilitySummary,
            capabilities: capabilities,
            opponentTeam: opponentTeam,
            location: location,
            homeTeamName: homeTeamName,
            teamId: teamId,
            date: date,
            startTime: startTime,
            homeScore: homeScore,
            awayScore: awayScore
        )
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        id = try container.decodeIfPresent(String.self, forKey: .mongoId)
            ?? container.decodeIfPresent(String.self, forKey: .id)
            ?? ""
        title = try container.decodeIfPresent(String.self, forKey: .title) ?? L10n.defaultMatchTitle
        status = try container.decodeIfPresent(MatchStatus.self, forKey: .status) ?? .upcoming
        statusLabel = try container.decodeIfPresent(String.self, forKey: .statusLabel)
        preparationPhase = try container.decodeIfPresent(MatchPreparationPhase.self, forKey: .preparationPhase)
        isPreparationLocked = try container.decodeIfPresent(Bool.self, forKey: .isPreparationLocked) ?? false
        isCompositionLocked = try container.decodeIfPresent(Bool.self, forKey: .isCompositionLocked) ?? false
        canPublish = try container.decodeIfPresent(Bool.self, forKey: .canPublish) ?? false
        publishBlockers = try container.decodeIfPresent([PublishBlocker].self, forKey: .publishBlockers) ?? []
        myAvailabilityStatus = try container.decodeIfPresent(MatchAvailabilityStatus.self, forKey: .myAvailabilityStatus)
        availabilitySummary = try container.decodeIfPresent(AvailabilitySummary.self, forKey: .availabilitySummary)
        capabilities = try container.decodeIfPresent(MatchCapabilities.self, forKey: .capabilities) ?? .empty
        opponentTeam = try container.decodeIfPresent(String.self, forKey: .opponentTeam)
        location = try container.decodeIfPresent(String.self, forKey: .location)
        homeTeamName = MatchSharedDecoding.resolveTeamName(
            from: container,
            homeTeamName: .homeTeamName,
            homeTeam: .homeTeam,
            team: .team
        )
        teamId = MatchSharedDecoding.resolveTeamId(
            from: container,
            teamId: .teamId,
            homeTeam: .homeTeam,
            team: .team
        )
        startTime = try container.decodeIfPresent(String.self, forKey: .startTime)
            ?? container.decodeIfPresent(String.self, forKey: .time)
        homeScore = try container.decodeIfPresent(Int.self, forKey: .homeScore)
            ?? container.decodeIfPresent(Int.self, forKey: .scoreHome)
        awayScore = try container.decodeIfPresent(Int.self, forKey: .awayScore)
            ?? container.decodeIfPresent(Int.self, forKey: .scoreAway)
        if let dateString = try? container.decodeIfPresent(String.self, forKey: .date)
            ?? container.decodeIfPresent(String.self, forKey: .matchDate) {
            date = MatchSharedDecoding.parseDateString(dateString) ?? Date()
        } else {
            date = Date()
        }
        composition = try container.decodeIfPresent(TeamComposition.self, forKey: .composition)
    }

    init(
        id: String,
        title: String,
        status: MatchStatus,
        statusLabel: String?,
        preparationPhase: MatchPreparationPhase?,
        isPreparationLocked: Bool,
        isCompositionLocked: Bool,
        canPublish: Bool,
        publishBlockers: [PublishBlocker],
        myAvailabilityStatus: MatchAvailabilityStatus?,
        availabilitySummary: AvailabilitySummary?,
        capabilities: MatchCapabilities,
        opponentTeam: String?,
        location: String?,
        homeTeamName: String?,
        teamId: String?,
        date: Date,
        startTime: String?,
        homeScore: Int?,
        awayScore: Int?,
        composition: TeamComposition?
    ) {
        self.id = id
        self.title = title
        self.status = status
        self.statusLabel = statusLabel
        self.preparationPhase = preparationPhase
        self.isPreparationLocked = isPreparationLocked
        self.isCompositionLocked = isCompositionLocked
        self.canPublish = canPublish
        self.publishBlockers = publishBlockers
        self.myAvailabilityStatus = myAvailabilityStatus
        self.availabilitySummary = availabilitySummary
        self.capabilities = capabilities
        self.opponentTeam = opponentTeam
        self.location = location
        self.homeTeamName = homeTeamName
        self.teamId = teamId
        self.date = date
        self.startTime = startTime
        self.homeScore = homeScore
        self.awayScore = awayScore
        self.composition = composition
    }

    func preservingPresentationContext(from previous: MatchDetail) -> MatchDetail {
        MatchDetail(
            id: id.isEmpty ? previous.id : id,
            title: title.isEmpty ? previous.title : title,
            status: status,
            statusLabel: statusLabel ?? previous.statusLabel,
            preparationPhase: preparationPhase ?? previous.preparationPhase,
            isPreparationLocked: isPreparationLocked,
            isCompositionLocked: isCompositionLocked || previous.isCompositionLocked,
            canPublish: canPublish || previous.canPublish,
            publishBlockers: publishBlockers.isEmpty ? previous.publishBlockers : publishBlockers,
            myAvailabilityStatus: myAvailabilityStatus ?? previous.myAvailabilityStatus,
            availabilitySummary: availabilitySummary ?? previous.availabilitySummary,
            capabilities: capabilities.merged(with: previous.capabilities),
            opponentTeam: opponentTeam ?? previous.opponentTeam,
            location: location ?? previous.location,
            homeTeamName: homeTeamName ?? previous.homeTeamName,
            teamId: teamId ?? previous.teamId,
            date: date,
            startTime: startTime ?? previous.startTime,
            homeScore: homeScore ?? previous.homeScore,
            awayScore: awayScore ?? previous.awayScore,
            composition: mergedComposition(current: composition, previous: previous.composition)
        )
    }

    private func mergedComposition(
        current: TeamComposition?,
        previous: TeamComposition?
    ) -> TeamComposition? {
        switch (current, previous) {
        case (nil, nil):
            return nil
        case (nil, let previous?):
            return previous
        case (let current?, nil):
            return current
        case (let current?, let previous?):
            return current.enriched(from: previous)
        }
    }

    func replacingComposition(_ composition: TeamComposition?) -> MatchDetail {
        MatchDetail(
            id: id,
            title: title,
            status: status,
            statusLabel: statusLabel,
            preparationPhase: preparationPhase,
            isPreparationLocked: isPreparationLocked,
            isCompositionLocked: isCompositionLocked,
            canPublish: canPublish,
            publishBlockers: publishBlockers,
            myAvailabilityStatus: myAvailabilityStatus,
            availabilitySummary: availabilitySummary,
            capabilities: capabilities,
            opponentTeam: opponentTeam,
            location: location,
            homeTeamName: homeTeamName,
            teamId: teamId,
            date: date,
            startTime: startTime,
            homeScore: homeScore,
            awayScore: awayScore,
            composition: composition
        )
    }

    var showsPrepareHub: Bool {
        guard status.isPreparationStatus else { return false }
        return uxMode == .prepare
            || capabilities.canPublish
            || capabilities.canManageAvailability
            || composition != nil
    }

    /// Ajout / suppression d'événements pendant le match ou après coup (corrections staff).
    var allowsEventCorrections: Bool {
        guard status == .ongoing || status == .finished else { return false }
        if capabilities.canManageEvents { return true }
        if status == .finished {
            return capabilities.canUpdateScore
                || capabilities.canPublish
                || capabilities.canManageAvailability
        }
        return false
    }

    private enum CodingKeys: String, CodingKey {
        case mongoId = "_id"
        case id
        case title
        case status
        case statusLabel
        case preparationPhase
        case isPreparationLocked
        case isCompositionLocked
        case canPublish
        case publishBlockers
        case myAvailabilityStatus
        case availabilitySummary
        case capabilities
        case opponentTeam
        case location
        case homeTeamName
        case teamId
        case homeTeam
        case team
        case date
        case matchDate
        case startTime
        case time
        case homeScore
        case awayScore
        case scoreHome
        case scoreAway
        case composition
    }
}

// MARK: - Availability

struct MatchAvailabilityEntry: Decodable, Identifiable, Hashable {
    let playerId: String
    let userId: String?
    let memberId: String?
    let firstName: String?
    let lastName: String?
    let status: MatchAvailabilityStatus
    let source: AvailabilitySource

    var id: String { playerId }

    var availabilityRequestId: String {
        userId ?? memberId ?? playerId
    }

    var displayName: String {
        [firstName, lastName]
            .compactMap { $0?.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
            .joined(separator: " ")
    }

    init(
        playerId: String,
        userId: String? = nil,
        memberId: String? = nil,
        firstName: String? = nil,
        lastName: String? = nil,
        status: MatchAvailabilityStatus = .unknown,
        source: AvailabilitySource = .selfDeclared
    ) {
        self.playerId = playerId
        self.userId = userId
        self.memberId = memberId
        self.firstName = firstName
        self.lastName = lastName
        self.status = status
        self.source = source
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        let nestedUser = try container.decodeIfPresent(AvailabilityUser.self, forKey: .user)
            ?? container.decodeIfPresent(AvailabilityUser.self, forKey: .member)
            ?? container.decodeIfPresent(AvailabilityUser.self, forKey: .player)

        let decodedUserId = try container.decodeIfPresent(String.self, forKey: .userId) ?? nestedUser?.userId
        let memberIdFromKey = try container.decodeIfPresent(String.self, forKey: .memberId)
        let playerIdFromKey = try container.decodeIfPresent(String.self, forKey: .playerId)
        let mongoIdFromKey = try container.decodeIfPresent(String.self, forKey: .mongoId)
        let idFromKey = try container.decodeIfPresent(String.self, forKey: .id)
        let decodedMemberId = memberIdFromKey ?? playerIdFromKey ?? mongoIdFromKey ?? idFromKey

        userId = decodedUserId
        memberId = decodedMemberId
        playerId = Self.resolvePlayerId(from: container, nestedUser: nestedUser, userId: decodedUserId, memberId: decodedMemberId)
        firstName = try container.decodeIfPresent(String.self, forKey: .firstName) ?? nestedUser?.firstName
        lastName = try container.decodeIfPresent(String.self, forKey: .lastName) ?? nestedUser?.lastName

        if let decodedStatus = try container.decodeIfPresent(MatchAvailabilityStatus.self, forKey: .status) {
            status = decodedStatus
        } else if let decodedStatus = try container.decodeIfPresent(MatchAvailabilityStatus.self, forKey: .availabilityStatus) {
            status = decodedStatus
        } else if let decodedStatus = try container.decodeIfPresent(MatchAvailabilityStatus.self, forKey: .availability) {
            status = decodedStatus
        } else {
            status = .unknown
        }

        source = try container.decodeIfPresent(AvailabilitySource.self, forKey: .source) ?? .selfDeclared
    }

    private enum CodingKeys: String, CodingKey {
        case mongoId = "_id"
        case id
        case playerId
        case memberId
        case userId
        case firstName
        case lastName
        case status
        case availabilityStatus
        case availability
        case source
        case user
        case member
        case player
    }

    private struct AvailabilityUser: Decodable {
        let id: String?
        let userId: String?
        let firstName: String?
        let lastName: String?
    }

    private static func resolvePlayerId(
        from container: KeyedDecodingContainer<CodingKeys>,
        nestedUser: AvailabilityUser?,
        userId: String?,
        memberId: String?
    ) -> String {
        let directId = [
            userId,
            memberId,
            try? container.decodeIfPresent(String.self, forKey: .playerId),
            try? container.decodeIfPresent(String.self, forKey: .userId),
            try? container.decodeIfPresent(String.self, forKey: .memberId),
            try? container.decodeIfPresent(String.self, forKey: .mongoId),
            try? container.decodeIfPresent(String.self, forKey: .id),
            nestedUser?.userId,
            nestedUser?.id
        ]
            .compactMap { $0 }
            .first { !$0.isEmpty }

        return directId ?? ""
    }

    func matchesPlayer(_ other: MatchAvailabilityEntry) -> Bool {
        let ids = Set([playerId, userId, memberId].compactMap { $0 }.filter { !$0.isEmpty })
        let otherIds = Set([other.playerId, other.userId, other.memberId].compactMap { $0 }.filter { !$0.isEmpty })
        return !ids.isDisjoint(with: otherIds)
    }

    static func sortedByName(_ entries: [MatchAvailabilityEntry]) -> [MatchAvailabilityEntry] {
        entries.sorted { lhs, rhs in
            lhs.displayName.localizedCaseInsensitiveCompare(rhs.displayName) == .orderedAscending
        }
    }
}

struct MatchAvailabilityRoster: Decodable, Equatable {
    let members: [MatchAvailabilityEntry]
    let guests: [MatchAvailabilityEntry]
    let all: [MatchAvailabilityEntry]
    let summary: AvailabilitySummary?

    init(
        members: [MatchAvailabilityEntry] = [],
        guests: [MatchAvailabilityEntry] = [],
        all: [MatchAvailabilityEntry] = [],
        summary: AvailabilitySummary? = nil
    ) {
        self.members = members
        self.guests = guests
        self.all = all
        self.summary = summary
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        members = try container.decodeIfPresent([MatchAvailabilityEntry].self, forKey: .members) ?? []
        guests = try container.decodeIfPresent([MatchAvailabilityEntry].self, forKey: .guests) ?? []
        all = try container.decodeIfPresent([MatchAvailabilityEntry].self, forKey: .all) ?? []
        summary = try container.decodeIfPresent(AvailabilitySummary.self, forKey: .summary)
    }

    var resolvedEntries: [MatchAvailabilityEntry] {
        let entries = !all.isEmpty ? all : members + guests
        return MatchAvailabilityEntry.sortedByName(
            entries.filter { !$0.playerId.isEmpty }
        )
    }

    private enum CodingKeys: String, CodingKey {
        case members
        case guests
        case all
        case summary
    }
}

extension MatchAvailabilityEntry {
    static func from(selectablePlayer: MatchSelectablePlayer) -> MatchAvailabilityEntry {
        MatchAvailabilityEntry(
            playerId: selectablePlayer.userId ?? selectablePlayer.id,
            userId: selectablePlayer.userId,
            memberId: selectablePlayer.id,
            firstName: selectablePlayer.firstName,
            lastName: selectablePlayer.lastName
        )
    }

    static func from(member: TeamMember) -> MatchAvailabilityEntry {
        MatchAvailabilityEntry(
            playerId: member.userId ?? member.id,
            userId: member.userId,
            memberId: member.id,
            firstName: member.firstName,
            lastName: member.lastName
        )
    }

    func asSelectablePlayer(isGuest explicitGuest: Bool = false) -> MatchSelectablePlayer {
        let guest = explicitGuest
            || CompositionMemberKey.isGuestKey(playerId)
            || CompositionMemberKey.isGuestKey(userId ?? "")
        let rawId = CompositionMemberKey.rawGuestId(from: playerId.isEmpty ? (userId ?? memberId ?? "") : playerId)
        return MatchSelectablePlayer(
            id: rawId,
            userId: guest ? nil : (userId ?? playerId),
            firstName: firstName,
            lastName: lastName,
            isGuest: guest
        )
    }

    static func merge(apiResponses: [MatchAvailabilityEntry], teamRoster: [MatchAvailabilityEntry]) -> [MatchAvailabilityEntry] {
        guard !teamRoster.isEmpty else {
            return sortedByName(apiResponses)
        }

        return teamRoster.map { player in
            guard let response = apiResponses.first(where: { $0.matchesPlayer(player) }) else {
                return player
            }

            return MatchAvailabilityEntry(
                playerId: player.playerId,
                userId: player.userId ?? response.userId,
                memberId: player.memberId ?? response.memberId,
                firstName: player.firstName ?? response.firstName,
                lastName: player.lastName ?? response.lastName,
                status: response.status,
                source: response.source
            )
        }
        .sorted { lhs, rhs in
            lhs.displayName.localizedCaseInsensitiveCompare(rhs.displayName) == .orderedAscending
        }
    }
}

struct MyAvailabilityResponse: Decodable, Equatable, Hashable {
    let status: MatchAvailabilityStatus
    let source: AvailabilitySource?

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        status = try container.decodeIfPresent(MatchAvailabilityStatus.self, forKey: .status) ?? .unknown
        source = try container.decodeIfPresent(AvailabilitySource.self, forKey: .source)
    }

    private enum CodingKeys: String, CodingKey {
        case status
        case source
    }
}

struct MatchSelectablePlayer: Decodable, Identifiable, Hashable {
    let id: String
    let userId: String?
    let firstName: String?
    let lastName: String?
    let isGuest: Bool?

    var displayName: String {
        [firstName, lastName]
            .compactMap { $0?.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
            .joined(separator: " ")
    }

    init(
        id: String,
        userId: String? = nil,
        firstName: String? = nil,
        lastName: String? = nil,
        isGuest: Bool? = nil
    ) {
        self.id = id
        self.userId = userId
        self.firstName = firstName
        self.lastName = lastName
        self.isGuest = isGuest
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        let nestedUser = try container.decodeIfPresent(PlayerUser.self, forKey: .user)
            ?? container.decodeIfPresent(PlayerUser.self, forKey: .member)
            ?? container.decodeIfPresent(PlayerUser.self, forKey: .player)

        var resolvedId = try container.decodeIfPresent(String.self, forKey: .mongoId)
            ?? container.decodeIfPresent(String.self, forKey: .id)
            ?? container.decodeIfPresent(String.self, forKey: .userId)
            ?? nestedUser?.userId
            ?? nestedUser?.id
            ?? ""
        var resolvedUserId = try container.decodeIfPresent(String.self, forKey: .userId) ?? nestedUser?.userId
        firstName = try container.decodeIfPresent(String.self, forKey: .firstName) ?? nestedUser?.firstName
        lastName = try container.decodeIfPresent(String.self, forKey: .lastName) ?? nestedUser?.lastName

        let decodedGuestFlag: Bool?
        if let type = try container.decodeIfPresent(String.self, forKey: .type) {
            decodedGuestFlag = type.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() == "guest"
        } else {
            decodedGuestFlag = try container.decodeIfPresent(Bool.self, forKey: .isGuest)
        }

        let guest = decodedGuestFlag
            ?? CompositionMemberKey.isGuestKey(resolvedId)
            || CompositionMemberKey.isGuestKey(resolvedUserId ?? "")
        isGuest = guest

        if guest {
            resolvedId = CompositionMemberKey.rawGuestId(
                from: resolvedId.isEmpty ? (resolvedUserId ?? "") : resolvedId
            )
            resolvedUserId = nil
        } else if resolvedUserId == nil {
            resolvedUserId = resolvedId
        }

        id = resolvedId
        userId = resolvedUserId
    }

    private enum CodingKeys: String, CodingKey {
        case mongoId = "_id"
        case id
        case userId
        case firstName
        case lastName
        case isGuest
        case type
        case user
        case member
        case player
    }

    private struct PlayerUser: Decodable {
        let id: String?
        let userId: String?
        let firstName: String?
        let lastName: String?
    }
}

// MARK: - Events

struct MatchEventPlayer: Decodable, Hashable {
    let id: String
    let firstName: String?
    let lastName: String?

    var displayName: String {
        [firstName, lastName]
            .compactMap { $0?.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
            .joined(separator: " ")
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decodeIfPresent(String.self, forKey: .mongoId)
            ?? container.decodeIfPresent(String.self, forKey: .id)
            ?? ""
        firstName = try container.decodeIfPresent(String.self, forKey: .firstName)
        lastName = try container.decodeIfPresent(String.self, forKey: .lastName)
    }

    private enum CodingKeys: String, CodingKey {
        case mongoId = "_id"
        case id
        case firstName
        case lastName
    }
}

struct MatchEvent: Decodable, Identifiable, Hashable {
    let id: String
    let type: MatchEventType
    let minute: Int?
    let playerId: String?
    let playerName: String?
    let comment: String?
    let isActive: Bool
    let createdAt: Date?

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decodeIfPresent(String.self, forKey: .mongoId)
            ?? container.decodeIfPresent(String.self, forKey: .id)
            ?? ""
        type = MatchEvent.decodeType(from: container)
        minute = try container.decodeIfPresent(Int.self, forKey: .minute)
        let player = MatchEvent.decodePlayer(from: container)
        playerId = player.id
        playerName = player.name
        comment = try container.decodeIfPresent(String.self, forKey: .comment)
        isActive = try container.decodeIfPresent(Bool.self, forKey: .isActive) ?? true
        createdAt = MatchSharedDecoding.parseDateString(
            (try? container.decodeIfPresent(String.self, forKey: .createdAt))
                ?? (try? container.decodeIfPresent(String.self, forKey: .timestamp))
                ?? ""
        )
    }

    private enum CodingKeys: String, CodingKey {
        case mongoId = "_id"
        case id
        case type
        case minute
        case player
        case comment
        case isActive
        case createdAt
        case timestamp
    }

    private static func decodeType(from container: KeyedDecodingContainer<CodingKeys>) -> MatchEventType {
        if let type = try? container.decode(MatchEventType.self, forKey: .type) {
            return type
        }
        if let rawType = try? container.decode(String.self, forKey: .type),
           let resolved = MatchEventType.resolve(from: rawType) {
            return resolved
        }
        return .other
    }

    private static func decodePlayer(
        from container: KeyedDecodingContainer<CodingKeys>
    ) -> (id: String?, name: String?) {
        if let player = try? container.decode(MatchEventPlayer.self, forKey: .player) {
            let name = player.displayName
            return (
                player.id.isEmpty ? nil : player.id,
                name.isEmpty ? nil : name
            )
        }

        if let playerId = try? container.decode(String.self, forKey: .player),
           !playerId.isEmpty {
            return (playerId, nil)
        }

        return (nil, nil)
    }
}

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

// MARK: - Decoding helpers

enum MatchDecoding {
    private struct AvailabilityListPayload: Decodable {
        let availability: [MatchAvailabilityEntry]?
        let items: [MatchAvailabilityEntry]?
        let players: [MatchAvailabilityEntry]?
        let entries: [MatchAvailabilityEntry]?
    }

    static func decodeDetail(from data: Data) throws -> MatchDetail {
        if let detail = try? APIResponseDecoder.decodePayload(MatchDetail.self, from: data) {
            return detail
        }
        return try APIResponseDecoder.decode(MatchDetail.self, from: data)
    }

    static func decodeAvailabilityRoster(from data: Data) throws -> MatchAvailabilityRoster {
        if let roster = try? APIResponseDecoder.decodePayload(MatchAvailabilityRoster.self, from: data) {
            return roster
        }
        return try APIResponseDecoder.decode(MatchAvailabilityRoster.self, from: data)
    }

    static func decodeAvailabilityList(from data: Data) throws -> [MatchAvailabilityEntry] {
        if let entries = try? APIResponseDecoder.decodePayload([MatchAvailabilityEntry].self, from: data) {
            return entries.filter { !$0.playerId.isEmpty }
        }
        if let entries = try? APIResponseDecoder.decode([MatchAvailabilityEntry].self, from: data) {
            return entries.filter { !$0.playerId.isEmpty }
        }

        if let payload = try? APIResponseDecoder.decodePayload(AvailabilityListPayload.self, from: data) {
            return mergedAvailability(from: payload)
        }

        if let payload = try? JSONDecoder().decode(AvailabilityListPayload.self, from: data) {
            return mergedAvailability(from: payload)
        }

        return []
    }

    private static func mergedAvailability(from payload: AvailabilityListPayload) -> [MatchAvailabilityEntry] {
        let entries = payload.players
            ?? payload.availability
            ?? payload.items
            ?? payload.entries
            ?? []
        return entries.filter { !$0.playerId.isEmpty }
    }

    static func decodeSelectablePlayers(from data: Data) throws -> [MatchSelectablePlayer] {
        if let players = try? APIResponseDecoder.decodePayload([MatchSelectablePlayer].self, from: data) {
            return players.filter { !$0.id.isEmpty }
        }
        if let players = try? APIResponseDecoder.decode([MatchSelectablePlayer].self, from: data) {
            return players.filter { !$0.id.isEmpty }
        }

        struct SelectablePlayersPayload: Decodable {
            let players: [MatchSelectablePlayer]?
            let items: [MatchSelectablePlayer]?
            let all: [MatchSelectablePlayer]?
            let members: [MatchSelectablePlayer]?
            let guests: [MatchSelectablePlayer]?

            var resolved: [MatchSelectablePlayer] {
                if let all, !all.isEmpty {
                    return all
                }
                let combined = (members ?? []) + (guests ?? [])
                if !combined.isEmpty {
                    return combined
                }
                return players ?? items ?? []
            }
        }

        if let payload = try? APIResponseDecoder.decodePayload(SelectablePlayersPayload.self, from: data) {
            return payload.resolved.filter { !$0.id.isEmpty }
        }

        if let payload = try? JSONDecoder().decode(SelectablePlayersPayload.self, from: data) {
            return payload.resolved.filter { !$0.id.isEmpty }
        }

        return []
    }

    static func decodeEvents(from data: Data) throws -> [MatchEvent] {
        let events: [MatchEvent]
        if let decoded = try? APIResponseDecoder.decodePayload([MatchEvent].self, from: data) {
            events = decoded
        } else if let decoded = try? APIResponseDecoder.decode([MatchEvent].self, from: data) {
            events = decoded
        } else {
            struct EventsPayload: Decodable {
                let events: [MatchEvent]?
                let items: [MatchEvent]?
            }

            if let payload = try? APIResponseDecoder.decodePayload(EventsPayload.self, from: data) {
                events = payload.events ?? payload.items ?? []
            } else {
                events = []
            }
        }

        return events.filter(\.isActive)
    }
}

extension PublishBlocker {
    var localizedMessage: String {
        switch self {
        case .missingMinimalInfo:
            return L10n.publishBlockerMissingMinimalInfo
        case .missingComposition:
            return L10n.publishBlockerMissingComposition
        case .insufficientAvailabilityResponses:
            return L10n.publishBlockerInsufficientAvailability
        case .unknown(let code):
            return code
        }
    }
}

private extension String {
    func snakeCaseToLowerCamel() -> String {
        let parts = split(separator: "_")
        guard let first = parts.first else { return self }
        let head = String(first)
        let tail = parts.dropFirst().map { part in
            part.prefix(1).uppercased() + part.dropFirst()
        }.joined()
        return head + tail
    }
}
