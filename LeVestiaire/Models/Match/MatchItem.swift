//
//  MatchItem.swift
//  LeVestaire
//
//  Created by Corentin Robert on 17/06/2026.
//

import Foundation

struct MatchItem: Identifiable, Decodable, Hashable {
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

    var scoreText: String? {
        guard let homeScore, let awayScore else { return nil }
        return "\(homeScore) - \(awayScore)"
    }

    var showsScore: Bool {
        status == .finished || status == .ongoing
    }

    var formattedDate: String {
        Self.makeDisplayDateFormatter().string(from: date)
    }

    var formattedTime: String? {
        if let startTime, !startTime.isEmpty {
            return startTime
        }
        return Self.makeDisplayTimeFormatter().string(from: date)
    }

    var resolvedStatusLabel: String {
        statusLabel ?? status.displayName
    }

    var canRespondFromListing: Bool {
        capabilities.canRespond
    }

    var availabilityResponseText: String? {
        guard let myAvailabilityStatus else { return nil }
        return myAvailabilityStatus.displayName
    }

    var myAvailabilityLabel: String? {
        guard let myAvailabilityStatus else { return nil }
        return L10n.myAvailabilityResponse(myAvailabilityStatus.displayName)
    }

    var availabilitySummaryLabel: String? {
        guard let availabilitySummary else { return nil }
        return L10n.availabilityResponsesSummary(
            responded: availabilitySummary.respondedCount,
            total: availabilitySummary.totalEligible
        )
    }

    var showsPrepareOnListing: Bool {
        capabilities.canManageAvailability || capabilities.canPublish
    }

    var canEditFromListing: Bool {
        status.isPreparationStatus
            && !isPreparationLocked
            && (
                capabilities.canPublish
                    || capabilities.canManageAvailability
                    || capabilities.canManageComposition
            )
    }

    init(
        id: String,
        title: String,
        status: MatchStatus,
        statusLabel: String? = nil,
        preparationPhase: MatchPreparationPhase? = nil,
        isPreparationLocked: Bool = false,
        isCompositionLocked: Bool = false,
        canPublish: Bool = false,
        publishBlockers: [PublishBlocker] = [],
        myAvailabilityStatus: MatchAvailabilityStatus? = nil,
        availabilitySummary: AvailabilitySummary? = nil,
        capabilities: MatchCapabilities = .empty,
        opponentTeam: String? = nil,
        location: String? = nil,
        homeTeamName: String? = nil,
        teamId: String? = nil,
        date: Date,
        startTime: String? = nil,
        homeScore: Int? = nil,
        awayScore: Int? = nil
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
        homeTeamName = try container.decodeIfPresent(String.self, forKey: .homeTeamName)
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
    }

    private static func makeDisplayDateFormatter() -> DateFormatter {
        let formatter = DateFormatter()
        formatter.locale = LocalizationManager.shared.locale
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter
    }

    private static func makeDisplayTimeFormatter() -> DateFormatter {
        let formatter = DateFormatter()
        formatter.locale = LocalizationManager.shared.locale
        formatter.dateStyle = .none
        formatter.timeStyle = .short
        return formatter
    }
}
