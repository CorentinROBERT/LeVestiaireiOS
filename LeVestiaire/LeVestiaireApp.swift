//
//  LeVestiaireApp.swift
//  LeVestiaire
//
//  Created by Corentin Robert on 08/06/2026.
//

import SwiftUI
import FirebaseCore

class AppDelegate: NSObject, UIApplicationDelegate {
  func application(_ application: UIApplication,
                   didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
    FirebaseApp.configure()

    return true
  }
}

@main
struct LeVestiaireApp: App {
    @ObservedObject private var localizationManager = LocalizationManager.shared
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    
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
