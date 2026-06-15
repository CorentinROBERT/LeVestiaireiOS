//
//  OnboardingStore.swift
//  LeVestaire
//
//  Created by Corentin Robert on 15/06/2026.
//

import Foundation

final class OnboardingStore {
    static let shared = OnboardingStore()

    private enum Keys {
        static let hasCompletedOnboarding = "hasCompletedOnboarding"
    }

    private let userDefaults: UserDefaults

    init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
    }

    var hasCompletedOnboarding: Bool {
        userDefaults.bool(forKey: Keys.hasCompletedOnboarding)
    }

    func markOnboardingCompleted() {
        userDefaults.set(true, forKey: Keys.hasCompletedOnboarding)
    }
}
