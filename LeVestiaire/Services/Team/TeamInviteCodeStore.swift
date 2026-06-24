//
//  TeamInviteCodeStore.swift
//  LeVestaire
//

import Foundation

final class TeamInviteCodeStore {
    static let shared = TeamInviteCodeStore()

    private enum Keys {
        static let pendingCode = "pendingTeamInviteCode"
    }

    private let userDefaults: UserDefaults

    init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
    }

    var pendingCode: String? {
        guard let raw = userDefaults.string(forKey: Keys.pendingCode) else { return nil }
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }

    func save(_ code: String) {
        let trimmed = code.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            clear()
            return
        }
        userDefaults.set(trimmed, forKey: Keys.pendingCode)
    }

    func clear() {
        userDefaults.removeObject(forKey: Keys.pendingCode)
    }
}
