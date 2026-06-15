//
//  AuthTokenStore.swift
//  LeVestaire
//
//  Created by Corentin Robert on 15/06/2026.
//

import Foundation

final class AuthTokenStore {
    static let shared = AuthTokenStore()

    private enum Keys {
        static let accessToken = "accessToken"
        static let refreshToken = "refreshToken"
    }

    private let userDefaults: UserDefaults

    init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
    }

    func loadTokens() -> AuthTokens? {
        guard let accessToken = userDefaults.string(forKey: Keys.accessToken),
              let refreshToken = userDefaults.string(forKey: Keys.refreshToken) else {
            return nil
        }

        return AuthTokens(accessToken: accessToken, refreshToken: refreshToken)
    }

    func saveTokens(accessToken: String, refreshToken: String) {
        userDefaults.set(accessToken, forKey: Keys.accessToken)
        userDefaults.set(refreshToken, forKey: Keys.refreshToken)
    }

    func clearTokens() {
        userDefaults.removeObject(forKey: Keys.accessToken)
        userDefaults.removeObject(forKey: Keys.refreshToken)
    }
}
