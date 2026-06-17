//
//  LeVestiaireApp.swift
//  LeVestiaire
//
//  Created by Corentin Robert on 08/06/2026.
//

import SwiftUI

@main
struct LeVestiaireApp: App {
    @ObservedObject private var localizationManager = LocalizationManager.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .id(localizationManager.language.rawValue)
                .environmentObject(AuthService.shared)
                .environmentObject(localizationManager)
                .environment(\.locale, localizationManager.locale)
                .task {
                    await AuthService.shared.initialize()
                }
        }
    }
}
