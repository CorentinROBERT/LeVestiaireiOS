//
//  AuthTokenStore.swift
//  LeVestaire
//

import Foundation

final class AuthTokenStore {
    static let shared = AuthTokenStore()

    private enum Keys {
        static let accessToken = "accessToken"
        static let refreshToken = "refreshToken"
    }

    private enum LegacyKeys {
        static let accessToken = "accessToken"
        static let refreshToken = "refreshToken"
    }

    private let service = "com.levestaire.auth"
    private let userDefaults: UserDefaults

    init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
        migrateFromUserDefaultsIfNeeded()
    }

    func loadTokens() -> AuthTokens? {
        guard let accessToken = KeychainHelper.load(service: service, account: Keys.accessToken),
              let refreshToken = KeychainHelper.load(service: service, account: Keys.refreshToken) else {
            return nil
        }

        return AuthTokens(accessToken: accessToken, refreshToken: refreshToken)
    }

    func saveTokens(accessToken: String, refreshToken: String) {
        try? KeychainHelper.save(accessToken, service: service, account: Keys.accessToken)
        try? KeychainHelper.save(refreshToken, service: service, account: Keys.refreshToken)
        userDefaults.removeObject(forKey: LegacyKeys.accessToken)
        userDefaults.removeObject(forKey: LegacyKeys.refreshToken)
    }

    func clearTokens() {
        KeychainHelper.delete(service: service, account: Keys.accessToken)
        KeychainHelper.delete(service: service, account: Keys.refreshToken)
        userDefaults.removeObject(forKey: LegacyKeys.accessToken)
        userDefaults.removeObject(forKey: LegacyKeys.refreshToken)
    }

    private func migrateFromUserDefaultsIfNeeded() {
        guard KeychainHelper.load(service: service, account: Keys.accessToken) == nil,
              let accessToken = userDefaults.string(forKey: LegacyKeys.accessToken),
              let refreshToken = userDefaults.string(forKey: LegacyKeys.refreshToken) else {
            return
        }

        saveTokens(accessToken: accessToken, refreshToken: refreshToken)
    }
}
