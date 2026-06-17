//
//  LocalizationManager.swift
//  LeVestaire
//
//  Created by Corentin Robert on 17/06/2026.
//

import Combine
import Foundation
import SwiftUI

@MainActor
final class LocalizationManager: ObservableObject {
    static let shared = LocalizationManager()

    private static let storageKey = "app_language"

    @Published private(set) var language: AppLanguage

    var locale: Locale {
        language.locale
    }

    var bundle: Bundle {
        Bundle.appLanguageBundle(for: language.rawValue)
    }

    init(userDefaults: UserDefaults = .standard) {
        if let rawValue = userDefaults.string(forKey: Self.storageKey),
           let savedLanguage = AppLanguage(rawValue: rawValue) {
            language = savedLanguage
        } else if let preferred = Locale.preferredLanguages.first,
                  preferred.hasPrefix("fr") {
            language = .french
        } else {
            language = .english
        }
    }

    func setLanguage(_ language: AppLanguage) {
        guard self.language != language else { return }
        self.language = language
        UserDefaults.standard.set(language.rawValue, forKey: Self.storageKey)
    }
}
