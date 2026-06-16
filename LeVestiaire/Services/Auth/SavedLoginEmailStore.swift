//
//  SavedLoginEmailStore.swift
//  LeVestaire
//
//  Created by Corentin Robert on 16/06/2026.
//

import Foundation

final class SavedLoginEmailStore {
    static let shared = SavedLoginEmailStore()

    private enum Keys {
        static let lastEmail = "auth.lastLoginEmail"
    }

    private let userDefaults: UserDefaults

    init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
    }

    func load() -> String? {
        userDefaults.string(forKey: Keys.lastEmail)
    }

    func save(_ email: String) {
        let trimmed = email.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        userDefaults.set(trimmed, forKey: Keys.lastEmail)
    }

    func clear() {
        userDefaults.removeObject(forKey: Keys.lastEmail)
    }
}
