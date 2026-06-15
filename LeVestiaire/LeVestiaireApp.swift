//
//  LeVestiaireApp.swift
//  LeVestiaire
//
//  Created by Corentin Robert on 08/06/2026.
//

import SwiftUI

@main
struct LeVestiaireApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(AuthService.shared)
                .task {
                    await AuthService.shared.initialize()
                }
        }
    }
}
