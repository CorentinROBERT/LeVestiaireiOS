//
//  SelectedTeamStore.swift
//  LeVestaire
//

import Foundation

final class SelectedTeamStore {
    static let shared = SelectedTeamStore()

    private let userDefaults: UserDefaults
    private let key = "selectedTeamId"

    init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
    }

    var selectedTeamId: String? {
        get { userDefaults.string(forKey: key) }
        set {
            if let newValue, !newValue.isEmpty {
                userDefaults.set(newValue, forKey: key)
            } else {
                userDefaults.removeObject(forKey: key)
            }
        }
    }
}
