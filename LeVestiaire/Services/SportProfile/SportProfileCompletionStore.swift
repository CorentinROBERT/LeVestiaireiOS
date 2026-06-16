//
//  SportProfileCompletionStore.swift
//  LeVestaire
//
//  Created by Corentin Robert on 16/06/2026.
//

import Foundation

final class SportProfileCompletionStore {
    static let shared = SportProfileCompletionStore()

    private enum Keys {
        static let requiresCompletion = "auth.requiresSportProfileCompletion"
    }

    private let userDefaults: UserDefaults

    init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
    }

    var isRequired: Bool {
        userDefaults.bool(forKey: Keys.requiresCompletion)
    }

    func markRequired() {
        userDefaults.set(true, forKey: Keys.requiresCompletion)
    }

    func markCompleted() {
        userDefaults.set(false, forKey: Keys.requiresCompletion)
    }

    func clear() {
        userDefaults.removeObject(forKey: Keys.requiresCompletion)
    }
}
