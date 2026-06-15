//
//  APIConfiguration.swift
//  LeVestaire
//
//  Created by Corentin Robert on 12/06/2026.
//

import Combine
import Foundation

final class APIConfiguration: ObservableObject {
    static let shared = APIConfiguration()

    private enum StorageKey {
        static let environment = "api.environment"
        static let customBaseURL = "api.customBaseURL"
    }

    @Published var environment: APIEnvironment {
        didSet { persist() }
    }

    @Published var customBaseURL: String {
        didSet { persist() }
    }

    var resolvedBaseURL: String {
        switch environment {
        case .production, .dev:
            return environment.defaultBaseURL
        case .custom:
            return customBaseURL.trimmingCharacters(in: .whitespacesAndNewlines)
        }
    }

    var healthCheckURL: String? {
        let base = resolvedBaseURL.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !base.isEmpty, let baseURL = URL(string: base) else { return nil }
        return baseURL.appending(path: "api/health").absoluteString
    }

    private let userDefaults: UserDefaults

    init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults

        if let rawValue = userDefaults.string(forKey: StorageKey.environment),
           let storedEnvironment = APIEnvironment(rawValue: rawValue) {
            self.environment = storedEnvironment
        } else {
            self.environment = .production
        }

        self.customBaseURL = userDefaults.string(forKey: StorageKey.customBaseURL) ?? ""
    }

    private func persist() {
        userDefaults.set(environment.rawValue, forKey: StorageKey.environment)
        userDefaults.set(customBaseURL, forKey: StorageKey.customBaseURL)
    }
}
