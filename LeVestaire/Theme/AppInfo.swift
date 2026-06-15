//
//  AppInfo.swift
//  LeVestaire
//
//  Created by Corentin Robert on 12/06/2026.
//

import Foundation

enum AppInfo {
    static var version: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "—"
    }

    static var buildNumber: String {
        Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "—"
    }

    static var versionLabel: String {
        "Version \(version)"
    }
}
