//
//  User.swift
//  LeVestaire
//
//  Created by Corentin Robert on 15/06/2026.
//

import Foundation

enum UserConstants {
    static let cmToMeters = 100.0
}

enum UserStatus {
    static let active = "active"
    static let inactive = "inactive"
    static let suspended = "suspended"
    static let retired = "retired"
}

struct User: Decodable, Equatable, Identifiable {
    let id: String
    let email: String
    let password: String
    let firstName: String
    let lastName: String
    let avatar: String?
    let isActive: Bool
    let isDeleted: Bool
    let emailVerified: Bool
    let lastLogin: Date?
    let refreshToken: String?
    let birthDate: Date?
    let nationality: String?
    let height: Double?
    let weight: Double?
    let isInjured: Bool
    let injuryDescription: String?
    let injuryReturnDate: Date?
    let status: String
    let accountDeletion: AccountDeletion?
    let isAnonymized: Bool
    let createdAt: Date
    let updatedAt: Date

    var isGuest: Bool {
        id.hasPrefix("guest_")
    }

    var guestId: String? {
        guard isGuest, id.count > 6 else { return nil }
        return String(id.dropFirst(6))
    }

    func displayName(deletedUserLabel: String? = nil) -> String {
        if isAnonymized {
            return deletedUserLabel ?? L10n.deletedUser
        }
        return fullName
    }

    var fullName: String {
        "\(firstName) \(lastName)".trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var initials: String {
        let firstInitial = firstName.trimmingCharacters(in: .whitespacesAndNewlines).first
        let lastInitial = lastName.trimmingCharacters(in: .whitespacesAndNewlines).first
        let value = [firstInitial, lastInitial]
            .compactMap { $0.map(String.init) }
            .joined()
            .uppercased()
        return value.isEmpty ? "?" : value
    }

    func age(referenceDate: Date = Date()) -> Int {
        guard let birthDate else { return 0 }

        let calendar = Calendar.current
        let age = calendar.dateComponents([.year], from: birthDate, to: referenceDate).year ?? 0
        return max(age, 0)
    }

    func bmi() -> Double {
        guard let height, let weight, height > 0 else { return 0 }

        let heightInMeters = height / UserConstants.cmToMeters
        return weight / (heightInMeters * heightInMeters)
    }

    func with(
        id: String? = nil,
        email: String? = nil,
        password: String? = nil,
        firstName: String? = nil,
        lastName: String? = nil,
        avatar: String?? = nil,
        isActive: Bool? = nil,
        isDeleted: Bool? = nil,
        emailVerified: Bool? = nil,
        lastLogin: Date?? = nil,
        refreshToken: String?? = nil,
        birthDate: Date?? = nil,
        nationality: String?? = nil,
        height: Double?? = nil,
        weight: Double?? = nil,
        isInjured: Bool? = nil,
        injuryDescription: String?? = nil,
        injuryReturnDate: Date?? = nil,
        status: String? = nil,
        accountDeletion: AccountDeletion?? = nil,
        isAnonymized: Bool? = nil,
        createdAt: Date? = nil,
        updatedAt: Date? = nil
    ) -> User {
        User(
            id: id ?? self.id,
            email: email ?? self.email,
            password: password ?? self.password,
            firstName: firstName ?? self.firstName,
            lastName: lastName ?? self.lastName,
            avatar: avatar ?? self.avatar,
            isActive: isActive ?? self.isActive,
            isDeleted: isDeleted ?? self.isDeleted,
            emailVerified: emailVerified ?? self.emailVerified,
            lastLogin: lastLogin ?? self.lastLogin,
            refreshToken: refreshToken ?? self.refreshToken,
            birthDate: birthDate ?? self.birthDate,
            nationality: nationality ?? self.nationality,
            height: height ?? self.height,
            weight: weight ?? self.weight,
            isInjured: isInjured ?? self.isInjured,
            injuryDescription: injuryDescription ?? self.injuryDescription,
            injuryReturnDate: injuryReturnDate ?? self.injuryReturnDate,
            status: status ?? self.status,
            accountDeletion: accountDeletion ?? self.accountDeletion,
            isAnonymized: isAnonymized ?? self.isAnonymized,
            createdAt: createdAt ?? self.createdAt,
            updatedAt: updatedAt ?? self.updatedAt
        )
    }

    init(
        id: String,
        email: String,
        password: String = "",
        firstName: String,
        lastName: String,
        avatar: String? = nil,
        isActive: Bool = false,
        isDeleted: Bool = false,
        emailVerified: Bool = false,
        lastLogin: Date? = nil,
        refreshToken: String? = nil,
        birthDate: Date? = nil,
        nationality: String? = nil,
        height: Double? = nil,
        weight: Double? = nil,
        isInjured: Bool = false,
        injuryDescription: String? = nil,
        injuryReturnDate: Date? = nil,
        status: String = UserStatus.active,
        accountDeletion: AccountDeletion? = nil,
        isAnonymized: Bool = false,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.email = email
        self.password = password
        self.firstName = firstName
        self.lastName = lastName
        self.avatar = avatar
        self.isActive = isActive
        self.isDeleted = isDeleted
        self.emailVerified = emailVerified
        self.lastLogin = lastLogin
        self.refreshToken = refreshToken
        self.birthDate = birthDate
        self.nationality = nationality
        self.height = height
        self.weight = weight
        self.isInjured = isInjured
        self.injuryDescription = injuryDescription
        self.injuryReturnDate = injuryReturnDate
        self.status = status
        self.accountDeletion = accountDeletion
        self.isAnonymized = isAnonymized
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        id = try container.decodeIfPresent(String.self, forKey: .mongoId)
            ?? container.decodeIfPresent(String.self, forKey: .id)
            ?? ""
        email = try container.decodeIfPresent(String.self, forKey: .email) ?? ""
        password = try container.decodeIfPresent(String.self, forKey: .password) ?? ""
        firstName = try container.decodeIfPresent(String.self, forKey: .firstName) ?? ""
        lastName = try container.decodeIfPresent(String.self, forKey: .lastName) ?? ""
        avatar = try container.decodeIfPresent(String.self, forKey: .avatar)
            ?? container.decodeIfPresent(String.self, forKey: .avatarUrl)
            ?? container.decodeIfPresent(String.self, forKey: .profileImageUrl)
            ?? container.decodeIfPresent(String.self, forKey: .profilePicture)
        isActive = try container.decodeIfPresent(Bool.self, forKey: .isActive) ?? false
        isDeleted = try container.decodeIfPresent(Bool.self, forKey: .isDeleted) ?? false
        emailVerified = try container.decodeIfPresent(Bool.self, forKey: .emailVerified) ?? false
        lastLogin = UserJSONParsing.parseDate(from: container, forKey: .lastLogin)
        refreshToken = try container.decodeIfPresent(String.self, forKey: .refreshToken)
        birthDate = UserJSONParsing.parseDate(from: container, forKey: .birthDate)
        nationality = try container.decodeIfPresent(String.self, forKey: .nationality)
        height = UserJSONParsing.parseDouble(from: container, forKey: .height)
        weight = UserJSONParsing.parseDouble(from: container, forKey: .weight)
        isInjured = try container.decodeIfPresent(Bool.self, forKey: .isInjured) ?? false
        injuryDescription = try container.decodeIfPresent(String.self, forKey: .injuryDescription)
        injuryReturnDate = UserJSONParsing.parseDate(from: container, forKey: .injuryReturnDate)
        status = try container.decodeIfPresent(String.self, forKey: .status) ?? UserStatus.active
        accountDeletion = try container.decodeIfPresent(AccountDeletion.self, forKey: .accountDeletion)
        isAnonymized = try container.decodeIfPresent(Bool.self, forKey: .isAnonymized) ?? false
        createdAt = UserJSONParsing.parseDate(from: container, forKey: .createdAt) ?? Date()
        updatedAt = UserJSONParsing.parseDate(from: container, forKey: .updatedAt) ?? Date()
    }

    private enum CodingKeys: String, CodingKey {
        case mongoId = "_id"
        case id
        case email
        case password
        case firstName
        case lastName
        case avatar
        case avatarUrl
        case profileImageUrl
        case profilePicture
        case isActive
        case isDeleted
        case emailVerified
        case lastLogin
        case refreshToken
        case birthDate
        case nationality
        case height
        case weight
        case isInjured
        case injuryDescription
        case injuryReturnDate
        case status
        case accountDeletion
        case isAnonymized
        case createdAt
        case updatedAt
    }
}

enum UserJSONParsing {
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

    static func parseDate(_ value: String?) -> Date? {
        guard let value else { return nil }

        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }

        return iso8601WithFractionalSeconds.date(from: trimmed)
            ?? iso8601.date(from: trimmed)
    }

    static func parseDate<K: CodingKey>(
        from container: KeyedDecodingContainer<K>,
        forKey key: K
    ) -> Date? {
        if let stringValue = try? container.decodeIfPresent(String.self, forKey: key) {
            return parseDate(stringValue)
        }

        if let dateValue = try? container.decodeIfPresent(Date.self, forKey: key) {
            return dateValue
        }

        return nil
    }

    static func parseDouble<K: CodingKey>(
        from container: KeyedDecodingContainer<K>,
        forKey key: K
    ) -> Double? {
        if let doubleValue = try? container.decodeIfPresent(Double.self, forKey: key) {
            return doubleValue
        }

        if let intValue = try? container.decodeIfPresent(Int.self, forKey: key) {
            return Double(intValue)
        }

        if let stringValue = try? container.decodeIfPresent(String.self, forKey: key) {
            return Double(stringValue)
        }

        return nil
    }
}
