//
//  AppRemoteSettings.swift
//  LeVestaire
//

import Foundation

struct AppRemoteSettings: Equatable {
    let minimumVersion: String?
    let recommendedVersion: String?
    let forceUpdate: ForceUpdateSettings?
    let maintenance: MaintenanceSettings?
    let featureFlags: FeatureFlags?

    static let `default` = AppRemoteSettings(
        minimumVersion: nil,
        recommendedVersion: nil,
        forceUpdate: nil,
        maintenance: nil,
        featureFlags: nil
    )
}

struct ForceUpdateSettings: Equatable {
    let enabled: Bool
    let storeURL: String?
    let message: LocalizedRemoteMessage?
}

struct MaintenanceSettings: Equatable {
    let enabled: Bool
    let message: LocalizedRemoteMessage?
}

struct FeatureFlags: Equatable {
    let pushEnabled: Bool?
    let quizEnabled: Bool?
}

struct LocalizedRemoteMessage: Equatable {
    let french: String?
    let english: String?

    func resolved(for language: AppLanguage) -> String? {
        switch language {
        case .french:
            return french ?? english
        case .english:
            return english ?? french
        }
    }
}

extension AppRemoteSettings {
    init?(snapshotValue: Any?) {
        guard let dictionary = snapshotValue as? [String: Any] else { return nil }
        self.init(dictionary: dictionary)
    }

    init(dictionary: [String: Any]) {
        minimumVersion = dictionary["minimumVersion"] as? String
        recommendedVersion = dictionary["recommendedVersion"] as? String
        forceUpdate = ForceUpdateSettings(dictionary: dictionary["forceUpdate"] as? [String: Any])
        maintenance = MaintenanceSettings(dictionary: dictionary["maintenance"] as? [String: Any])
        featureFlags = FeatureFlags(dictionary: dictionary["featureFlags"] as? [String: Any])
    }

    func isBelowMinimumVersion(_ currentVersion: String) -> Bool {
        guard let minimumVersion,
              SemanticVersion.isValid(minimumVersion),
              SemanticVersion.isValid(currentVersion) else {
            return false
        }

        return SemanticVersion.compare(currentVersion, minimumVersion) == .orderedAscending
    }

    var shouldForceUpdate: Bool {
        guard isBelowMinimumVersion(AppInfo.version) else { return false }
        if let forceUpdate {
            return forceUpdate.enabled
        }
        return true
    }

    var isMaintenanceEnabled: Bool {
        maintenance?.enabled == true
    }

    func featureFlag(_ keyPath: KeyPath<FeatureFlags, Bool?>, default defaultValue: Bool) -> Bool {
        featureFlags?[keyPath: keyPath] ?? defaultValue
    }
}

private extension ForceUpdateSettings {
    init?(dictionary: [String: Any]?) {
        guard let dictionary else { return nil }
        enabled = dictionary["enabled"] as? Bool ?? false
        storeURL = dictionary["storeURL"] as? String
        message = LocalizedRemoteMessage(dictionary: dictionary["message"] as? [String: Any])
    }
}

private extension MaintenanceSettings {
    init?(dictionary: [String: Any]?) {
        guard let dictionary else { return nil }
        enabled = dictionary["enabled"] as? Bool ?? false
        message = LocalizedRemoteMessage(dictionary: dictionary["message"] as? [String: Any])
    }
}

private extension FeatureFlags {
    init?(dictionary: [String: Any]?) {
        guard let dictionary else { return nil }
        pushEnabled = dictionary["pushEnabled"] as? Bool
        quizEnabled = dictionary["quizEnabled"] as? Bool
    }
}

private extension LocalizedRemoteMessage {
    init?(dictionary: [String: Any]?) {
        guard let dictionary else { return nil }
        french = dictionary["fr"] as? String
        english = dictionary["en"] as? String
    }
}
