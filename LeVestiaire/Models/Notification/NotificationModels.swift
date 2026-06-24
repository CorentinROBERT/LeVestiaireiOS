//
//  NotificationModels.swift
//  LeVestaire
//

import Foundation

enum NotificationChannel: String, Decodable, Equatable, CaseIterable {
    case push
    case inApp = "in_app"
    case email
    case unknown

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let raw = (try? container.decode(String.self))?.lowercased() ?? ""
        self = NotificationChannel(rawValue: raw) ?? .unknown
    }
}

enum NotificationTargetType: String, Decodable, Equatable, CaseIterable {
    case user
    case team
    case all
    case unknown

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let raw = (try? container.decode(String.self))?.lowercased() ?? ""
        self = NotificationTargetType(rawValue: raw) ?? .unknown
    }
}

enum NotificationCategory: String, Decodable, Equatable, CaseIterable {
    case sport
    case system
    case commercial
    case unknown

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let raw = (try? container.decode(String.self))?.lowercased() ?? ""
        self = NotificationCategory(rawValue: raw) ?? .unknown
    }

    var localizedLabel: String {
        switch self {
        case .sport:
            return L10n.text("notificationCategorySport")
        case .system:
            return L10n.text("notificationCategorySystem")
        case .commercial:
            return L10n.text("notificationCategoryCommercial")
        case .unknown:
            return L10n.text("notifications")
        }
    }

    var iconName: String {
        switch self {
        case .sport:
            return "sportscourt.fill"
        case .system:
            return "gearshape.fill"
        case .commercial:
            return "megaphone.fill"
        case .unknown:
            return "bell.fill"
        }
    }
}

enum NotificationType: String, Decodable, Equatable, CaseIterable {
    case matchCreated = "match_created"
    case matchUpdated = "match_updated"
    case matchReminder = "match_reminder"
    case teamInvitation = "team_invitation"
    case teamUpdate = "team_update"
    case playerEvent = "player_event"
    case compositionUpdated = "composition_updated"
    case matchResult = "match_result"
    case trainingScheduled = "training_scheduled"
    case trainingCancelled = "training_cancelled"
    case systemMaintenance = "system_maintenance"
    case systemUpdate = "system_update"
    case securityAlert = "security_alert"
    case accountVerification = "account_verification"
    case passwordReset = "password_reset"
    case dataBackup = "data_backup"
    case promotion
    case newFeature = "new_feature"
    case subscriptionReminder = "subscription_reminder"
    case premiumOffer = "premium_offer"
    case eventAnnouncement = "event_announcement"
    case partnershipNews = "partnership_news"
    case generic
    case unknown

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let raw = (try? container.decode(String.self))?.lowercased() ?? ""
        self = NotificationType(rawValue: raw) ?? .unknown
    }

    var category: NotificationCategory {
        switch self {
        case .matchCreated, .matchUpdated, .matchReminder, .teamInvitation, .teamUpdate,
             .playerEvent, .compositionUpdated, .matchResult, .trainingScheduled, .trainingCancelled:
            return .sport
        case .systemMaintenance, .systemUpdate, .securityAlert, .accountVerification,
             .passwordReset, .dataBackup:
            return .system
        case .promotion, .newFeature, .subscriptionReminder, .premiumOffer,
             .eventAnnouncement, .partnershipNews, .generic:
            return .commercial
        case .unknown:
            return .unknown
        }
    }

    var localizedLabel: String {
        switch self {
        case .matchCreated:
            return L10n.text("notificationTypeMatchCreated")
        case .matchUpdated:
            return L10n.text("notificationTypeMatchUpdated")
        case .matchReminder:
            return L10n.text("notificationTypeMatchReminder")
        case .teamInvitation:
            return L10n.text("notificationTypeTeamInvitation")
        case .teamUpdate:
            return L10n.text("notificationTypeTeamUpdate")
        case .playerEvent:
            return L10n.text("notificationTypePlayerEvent")
        case .compositionUpdated:
            return L10n.text("notificationTypeCompositionUpdated")
        case .matchResult:
            return L10n.text("notificationTypeMatchResult")
        case .trainingScheduled:
            return L10n.text("notificationTypeTrainingScheduled")
        case .trainingCancelled:
            return L10n.text("notificationTypeTrainingCancelled")
        case .systemMaintenance:
            return L10n.text("notificationTypeSystemMaintenance")
        case .systemUpdate:
            return L10n.text("notificationTypeSystemUpdate")
        case .securityAlert:
            return L10n.text("notificationTypeSecurityAlert")
        case .accountVerification:
            return L10n.text("notificationTypeAccountVerification")
        case .passwordReset:
            return L10n.text("notificationTypePasswordReset")
        case .dataBackup:
            return L10n.text("notificationTypeDataBackup")
        case .promotion:
            return L10n.text("notificationTypePromotion")
        case .newFeature:
            return L10n.text("notificationTypeNewFeature")
        case .subscriptionReminder:
            return L10n.text("notificationTypeSubscriptionReminder")
        case .premiumOffer:
            return L10n.text("notificationTypePremiumOffer")
        case .eventAnnouncement:
            return L10n.text("notificationTypeEventAnnouncement")
        case .partnershipNews:
            return L10n.text("notificationTypePartnershipNews")
        case .generic:
            return L10n.text("notificationTypeGeneric")
        case .unknown:
            return L10n.text("notificationTypeGeneric")
        }
    }

    var iconName: String {
        switch self {
        case .matchCreated, .matchUpdated, .matchResult:
            return "sportscourt.fill"
        case .matchReminder, .trainingScheduled:
            return "calendar.badge.clock"
        case .trainingCancelled:
            return "calendar.badge.minus"
        case .teamInvitation, .teamUpdate:
            return "person.3.fill"
        case .playerEvent:
            return "figure.soccer"
        case .compositionUpdated:
            return "person.3.sequence.fill"
        case .systemMaintenance, .systemUpdate, .dataBackup:
            return "gearshape.fill"
        case .securityAlert:
            return "shield.lefthalf.filled"
        case .accountVerification, .passwordReset:
            return "person.badge.key.fill"
        case .promotion, .premiumOffer:
            return "tag.fill"
        case .newFeature:
            return "sparkles"
        case .subscriptionReminder:
            return "creditcard.fill"
        case .eventAnnouncement, .partnershipNews:
            return "megaphone.fill"
        case .generic, .unknown:
            return "bell.fill"
        }
    }
}

struct NotificationMetadata: Decodable, Equatable {
    let matchId: String?
    let teamId: String?
    let teamName: String?
    let playerName: String?
    let playerId: String?
    let minute: Int?
    let opponentTeam: String?
    let timeLeft: String?
    let statType: String?
    let invitationId: String?
    let compositionId: String?
    let trainingId: String?

    init(
        matchId: String? = nil,
        teamId: String? = nil,
        teamName: String? = nil,
        playerName: String? = nil,
        playerId: String? = nil,
        minute: Int? = nil,
        opponentTeam: String? = nil,
        timeLeft: String? = nil,
        statType: String? = nil,
        invitationId: String? = nil,
        compositionId: String? = nil,
        trainingId: String? = nil
    ) {
        self.matchId = matchId
        self.teamId = teamId
        self.teamName = teamName
        self.playerName = playerName
        self.playerId = playerId
        self.minute = minute
        self.opponentTeam = opponentTeam
        self.timeLeft = timeLeft
        self.statType = statType
        self.invitationId = invitationId
        self.compositionId = compositionId
        self.trainingId = trainingId
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        matchId = Self.decodeString(from: container, forKey: .matchId)
        teamId = Self.decodeString(from: container, forKey: .teamId)
        teamName = try container.decodeIfPresent(String.self, forKey: .teamName)
        playerName = try container.decodeIfPresent(String.self, forKey: .playerName)
        playerId = Self.decodeString(from: container, forKey: .playerId)
        minute = TeamDecoding.decodeInt(from: container, forKey: .minute)
        opponentTeam = try container.decodeIfPresent(String.self, forKey: .opponentTeam)
        timeLeft = try container.decodeIfPresent(String.self, forKey: .timeLeft)
        statType = try container.decodeIfPresent(String.self, forKey: .statType)
        invitationId = Self.decodeString(from: container, forKey: .invitationId)
        compositionId = Self.decodeString(from: container, forKey: .compositionId)
        trainingId = Self.decodeString(from: container, forKey: .trainingId)
    }

    private enum CodingKeys: String, CodingKey {
        case matchId
        case teamId
        case teamName
        case playerName
        case playerId
        case minute
        case opponentTeam
        case timeLeft
        case statType
        case invitationId
        case compositionId
        case trainingId
    }

    private static func decodeString<K: CodingKey>(
        from container: KeyedDecodingContainer<K>,
        forKey key: K
    ) -> String? {
        if let value = try? container.decodeIfPresent(String.self, forKey: key) {
            let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
            return trimmed.isEmpty ? nil : trimmed
        }
        if let value = try? container.decodeIfPresent(Int.self, forKey: key) {
            return String(value)
        }
        return nil
    }
}

struct AppNotification: Identifiable, Decodable, Equatable {
    let id: String
    let userId: String?
    let targetType: NotificationTargetType
    let targetIds: [String]
    let title: String
    let body: String
    let imageUrl: String?
    let linkUrl: String?
    let deepLink: String?
    let type: NotificationType
    let category: NotificationCategory
    let channels: [NotificationChannel]
    let isRead: Bool
    let readAt: Date?
    let metadata: NotificationMetadata?
    let createdAt: Date
    let updatedAt: Date?

    var relativeTimestamp: String {
        let difference = Date().timeIntervalSince(createdAt)
        let days = Int(difference / 86_400)
        let hours = Int(difference / 3_600)
        let minutes = Int(difference / 60)

        if days > 0 {
            return days == 1 ? L10n.oneDayAgo : L10n.daysAgo(days)
        }
        if hours > 0 {
            return hours == 1 ? L10n.oneHourAgo : L10n.hoursAgo(hours)
        }
        if minutes > 1 {
            return L10n.minutesAgo(minutes)
        }
        return L10n.justNow
    }

    var isVisibleInApp: Bool {
        channels.isEmpty || channels.contains(.inApp)
    }

    var resolvedMatchId: String? {
        if let matchId = metadata?.matchId, !matchId.isEmpty {
            return matchId
        }
        return NotificationDeepLinkParser.matchId(from: deepLink)
    }

    var resolvedTeamId: String? {
        if let teamId = metadata?.teamId, !teamId.isEmpty {
            return teamId
        }
        if targetType == .team, let teamId = targetIds.first, !teamId.isEmpty {
            return teamId
        }
        return NotificationDeepLinkParser.teamId(from: deepLink)
    }

    var resolvedExternalURL: URL? {
        guard let linkUrl,
              let url = URL(string: linkUrl.trimmingCharacters(in: .whitespacesAndNewlines)),
              ["http", "https"].contains(url.scheme?.lowercased()) else {
            return nil
        }
        return url
    }

    var resolvedImageURL: URL? {
        guard let resolved = RemoteMediaURL.resolve(imageUrl) else { return nil }
        return URL(string: resolved)
    }

    var subtitleLabel: String {
        "\(category.localizedLabel) · \(type.localizedLabel)"
    }

    init(
        id: String,
        userId: String? = nil,
        targetType: NotificationTargetType = .user,
        targetIds: [String] = [],
        title: String,
        body: String,
        imageUrl: String? = nil,
        linkUrl: String? = nil,
        deepLink: String? = nil,
        type: NotificationType,
        category: NotificationCategory? = nil,
        channels: [NotificationChannel] = [.inApp],
        isRead: Bool,
        readAt: Date? = nil,
        metadata: NotificationMetadata? = nil,
        createdAt: Date,
        updatedAt: Date? = nil
    ) {
        self.id = id
        self.userId = userId
        self.targetType = targetType
        self.targetIds = targetIds
        self.title = title
        self.body = body
        self.imageUrl = imageUrl
        self.linkUrl = linkUrl
        self.deepLink = deepLink
        self.type = type
        self.category = category ?? type.category
        self.channels = channels
        self.isRead = isRead
        self.readAt = readAt
        self.metadata = metadata
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try TeamDecoding.decodeId(from: container)
        userId = Self.decodeOptionalString(from: container, forKey: .user)
        targetType = (try? container.decode(NotificationTargetType.self, forKey: .targetType)) ?? .user
        targetIds = Self.decodeStringArray(from: container, forKey: .targetIds)

        type = (try? container.decode(NotificationType.self, forKey: .type)) ?? .generic
        category = (try? container.decode(NotificationCategory.self, forKey: .category)) ?? type.category
        channels = (try? container.decode([NotificationChannel].self, forKey: .channels)) ?? [.inApp]

        let decodedTitle = try container.decodeIfPresent(String.self, forKey: .title)
        title = decodedTitle?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false
            ? decodedTitle!.trimmingCharacters(in: .whitespacesAndNewlines)
            : type.localizedLabel

        let decodedBody = try container.decodeIfPresent(String.self, forKey: .body)
            ?? container.decodeIfPresent(String.self, forKey: .message)
            ?? container.decodeIfPresent(String.self, forKey: .content)
        body = decodedBody?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""

        imageUrl = try container.decodeIfPresent(String.self, forKey: .imageUrl)
        linkUrl = try container.decodeIfPresent(String.self, forKey: .linkUrl)
        deepLink = try container.decodeIfPresent(String.self, forKey: .deepLink)

        readAt = Self.decodeOptionalDate(from: container, forKey: .readAt)

        if let explicitRead = try container.decodeIfPresent(Bool.self, forKey: .isRead) {
            isRead = explicitRead
        } else if readAt != nil {
            isRead = true
        } else {
            isRead = false
        }

        metadata = try container.decodeIfPresent(NotificationMetadata.self, forKey: .metadata)
        createdAt = Self.decodeDate(from: container, forKey: .createdAt) ?? Date()
        updatedAt = Self.decodeOptionalDate(from: container, forKey: .updatedAt)
    }

    func markingAsRead(at date: Date = Date()) -> AppNotification {
        AppNotification(
            id: id,
            userId: userId,
            targetType: targetType,
            targetIds: targetIds,
            title: title,
            body: body,
            imageUrl: imageUrl,
            linkUrl: linkUrl,
            deepLink: deepLink,
            type: type,
            category: category,
            channels: channels,
            isRead: true,
            readAt: date,
            metadata: metadata,
            createdAt: createdAt,
            updatedAt: updatedAt
        )
    }

    private enum CodingKeys: String, CodingKey {
        case mongoId = "_id"
        case id
        case user
        case targetType
        case targetIds
        case title
        case body
        case message
        case content
        case imageUrl
        case linkUrl
        case deepLink
        case type
        case category
        case channels
        case isRead
        case readAt
        case metadata
        case createdAt
        case updatedAt
    }

    private static func decodeOptionalString<K: CodingKey>(
        from container: KeyedDecodingContainer<K>,
        forKey key: K
    ) -> String? {
        if let value = try? container.decodeIfPresent(String.self, forKey: key) {
            let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
            return trimmed.isEmpty ? nil : trimmed
        }
        if let value = try? container.decodeIfPresent(Int.self, forKey: key) {
            return String(value)
        }
        return nil
    }

    private static func decodeStringArray<K: CodingKey>(
        from container: KeyedDecodingContainer<K>,
        forKey key: K
    ) -> [String] {
        if let values = try? container.decode([String].self, forKey: key) {
            return values.filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
        }
        if let value = decodeOptionalString(from: container, forKey: key) {
            return [value]
        }
        return []
    }

    private static func decodeOptionalDate<K: CodingKey>(
        from container: KeyedDecodingContainer<K>,
        forKey key: K
    ) -> Date? {
        if let date = try? container.decode(Date.self, forKey: key) {
            return date
        }
        if let raw = try? container.decode(String.self, forKey: key) {
            return MatchSharedDecoding.parseDateString(raw)
        }
        return nil
    }

    private static func decodeDate<K: CodingKey>(
        from container: KeyedDecodingContainer<K>,
        forKey key: K
    ) -> Date? {
        decodeOptionalDate(from: container, forKey: key)
    }
}

struct NotificationListResponse: Decodable {
    let success: Bool
    let message: String?
    let error: String?
    let notifications: [AppNotification]
    let pagination: PaginationInfo?

    var pageInfo: PaginationInfo? {
        pagination
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        success = try container.decodeIfPresent(Bool.self, forKey: .success) ?? true
        message = try container.decodeIfPresent(String.self, forKey: .message)
        error = try container.decodeIfPresent(String.self, forKey: .error)
        pagination = try container.decodeIfPresent(PaginationInfo.self, forKey: .pagination)

        let decoded: [AppNotification]
        if let array = try? container.decode([AppNotification].self, forKey: .data) {
            decoded = array
        } else if let nested = try? container.decode(NotificationListData.self, forKey: .data) {
            decoded = nested.items ?? nested.notifications ?? []
        } else {
            decoded = try container.decodeIfPresent([AppNotification].self, forKey: .notifications)
                ?? container.decodeIfPresent([AppNotification].self, forKey: .items)
                ?? []
        }

        notifications = decoded.filter(\.isVisibleInApp)
    }

    private enum CodingKeys: String, CodingKey {
        case success
        case message
        case error
        case data
        case notifications
        case items
        case pagination
    }
}

private struct NotificationListData: Decodable {
    let items: [AppNotification]?
    let notifications: [AppNotification]?
}

struct NotificationUnreadCountResponse: Decodable {
    let count: Int

    init(count: Int) {
        self.count = count
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        if let value = try container.decodeIfPresent(Int.self, forKey: .count) {
            count = value
            return
        }
        if let value = try container.decodeIfPresent(Int.self, forKey: .unreadCount) {
            count = value
            return
        }
        if let value = try container.decodeIfPresent(Int.self, forKey: .total) {
            count = value
            return
        }

        count = 0
    }

    private enum CodingKeys: String, CodingKey {
        case count
        case unreadCount
        case total
    }
}

enum NotificationFilter: String, CaseIterable, Identifiable {
    case all
    case unread

    var id: String { rawValue }

    var localizedTitle: String {
        switch self {
        case .all:
            return L10n.text("allNotifications")
        case .unread:
            return L10n.text("unreadNotifications")
        }
    }
}

enum NotificationDeepLinkParser {
    static func matchId(from deepLink: String?) -> String? {
        guard let deepLink, !deepLink.isEmpty else { return nil }
        return pathComponent(named: "matches", in: deepLink)
            ?? pathComponent(named: "match", in: deepLink)
            ?? queryValue(named: "matchId", in: deepLink)
    }

    static func teamId(from deepLink: String?) -> String? {
        guard let deepLink, !deepLink.isEmpty else { return nil }
        return pathComponent(named: "teams", in: deepLink)
            ?? pathComponent(named: "team", in: deepLink)
            ?? queryValue(named: "teamId", in: deepLink)
    }

    private static func pathComponent(named segment: String, in deepLink: String) -> String? {
        let normalized = deepLink
            .replacingOccurrences(of: "levestiaire://", with: "")
            .trimmingCharacters(in: CharacterSet(charactersIn: "/"))

        let parts = normalized.split(separator: "/").map(String.init)
        guard let index = parts.firstIndex(of: segment), index + 1 < parts.count else {
            return nil
        }

        let value = parts[index + 1].trimmingCharacters(in: .whitespacesAndNewlines)
        return value.isEmpty ? nil : value
    }

    private static func queryValue(named key: String, in deepLink: String) -> String? {
        guard let components = URLComponents(string: deepLink),
              let value = components.queryItems?.first(where: { $0.name == key })?.value else {
            return nil
        }
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }

    static func destination(from userInfo: [AnyHashable: Any]) -> NotificationNavigationDestination? {
        let payload = normalizedPayload(from: userInfo)

        if let matchId = stringValue(in: payload, keys: ["matchId", "match_id"]) {
            return .match(matchId)
        }

        if let teamId = stringValue(in: payload, keys: ["teamId", "team_id"]) {
            return .team(teamId)
        }

        if let deepLink = stringValue(in: payload, keys: ["deepLink", "deep_link", "linkUrl", "link_url"]) {
            if let matchId = matchId(from: deepLink) {
                return .match(matchId)
            }
            if let teamId = teamId(from: deepLink) {
                return .team(teamId)
            }
            if let url = URL(string: deepLink), ["http", "https"].contains(url.scheme?.lowercased() ?? "") {
                return .externalURL(url)
            }
        }

        if let urlString = stringValue(in: payload, keys: ["url", "externalUrl", "external_url"]),
           let url = URL(string: urlString),
           ["http", "https"].contains(url.scheme?.lowercased() ?? "") {
            return .externalURL(url)
        }

        return nil
    }

    private static func normalizedPayload(from userInfo: [AnyHashable: Any]) -> [String: Any] {
        var payload: [String: Any] = [:]

        for (key, value) in userInfo {
            guard let key = key as? String else { continue }
            payload[key] = value
        }

        if let nested = payload["data"] as? [String: Any] {
            for (key, value) in nested {
                payload[key] = value
            }
        } else if let json = payload["data"] as? String,
                  let data = json.data(using: .utf8),
                  let nested = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
            for (key, value) in nested {
                payload[key] = value
            }
        }

        return payload
    }

    private static func stringValue(in payload: [String: Any], keys: [String]) -> String? {
        for key in keys {
            if let value = payload[key] as? String {
                let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
                if !trimmed.isEmpty {
                    return trimmed
                }
            }
        }
        return nil
    }
}

enum NotificationDecoding {
    static func decodeUnreadCount(from data: Data) throws -> Int {
        if let payload = try? APIResponseDecoder.decodePayload(NotificationUnreadCountResponse.self, from: data) {
            return payload.count
        }

        if let payload = try? APIResponseDecoder.decode(NotificationUnreadCountResponse.self, from: data) {
            return payload.count
        }

        if let count = try? APIResponseDecoder.decodePayload(Int.self, from: data) {
            return count
        }

        return 0
    }
}

#if DEBUG
extension AppNotification {
    static let previewUnread = AppNotification(
        id: "preview-1",
        title: "Nouveau match planifié",
        body: "Votre équipe affronte FC Test samedi à 15h.",
        type: .matchCreated,
        isRead: false,
        metadata: NotificationMetadata(matchId: "match-preview", teamName: "FC Test"),
        createdAt: Date().addingTimeInterval(-1_800)
    )

    static let previewRead = AppNotification(
        id: "preview-2",
        title: "Invitation d'équipe",
        body: "Vous avez été invité à rejoindre FC Test.",
        type: .teamInvitation,
        isRead: true,
        metadata: NotificationMetadata(teamId: "team-preview", teamName: "FC Test"),
        createdAt: Date().addingTimeInterval(-86_400),
        updatedAt: Date().addingTimeInterval(-86_000)
    )
}
#endif
