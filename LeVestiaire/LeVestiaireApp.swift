//
//  LeVestiaireApp.swift
//  LeVestiaire
//
//  Created by Corentin Robert on 08/06/2026.
//

import SwiftUI
import FirebaseCore
import FirebaseMessaging
import UserNotifications

class AppDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate, MessagingDelegate {
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions _: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        #if DEBUG
        try? FileManager.default.removeItem(atPath: NSHomeDirectory() + "/Library/SplashBoard")
        #endif
        FirebaseApp.configure()

        UNUserNotificationCenter.current().delegate = self
        Messaging.messaging().delegate = self

        if UITestLaunchArgument.isEnabled {
            MainActor.assumeIsolated {
                UITestAppConfigurator.configureIfNeeded(authService: AuthService.shared)
            }
        } else {
            Task { @MainActor in
                PushNotificationManager.shared.configure(application: application)
            }
        }

        return true
    }

    func application(
        _ application: UIApplication,
        didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data
    ) {
        Task { @MainActor in
            PushNotificationManager.shared.setAPNSToken(deviceToken)
        }
    }

    func application(
        _ application: UIApplication,
        didFailToRegisterForRemoteNotificationsWithError error: Error
    ) {
        #if DEBUG
        print("[Push] APNs registration failed: \(error.localizedDescription)")
        #endif
    }

    func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
        Task { @MainActor in
            PushNotificationManager.shared.updateFCMToken(fcmToken)
        }
    }

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        let userInfo = notification.request.content.userInfo
        Task { @MainActor in
            PushNotificationManager.shared.handleForegroundNotification(userInfo: userInfo)
        }
        completionHandler([.banner, .sound, .badge])
    }

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        let userInfo = response.notification.request.content.userInfo
        Task { @MainActor in
            PushNotificationManager.shared.handleNotificationTap(userInfo: userInfo)
        }
        completionHandler()
    }
}

@main
struct LeVestiaireApp: App {
    @ObservedObject private var localizationManager = LocalizationManager.shared
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate

    init() {
        guard UITestLaunchArgument.isEnabled else { return }
        MainActor.assumeIsolated {
            UITestAppConfigurator.configureIfNeeded(authService: AuthService.shared)
        }
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(AuthService.shared)
                .environmentObject(localizationManager)
                .environmentObject(TeamInviteCoordinator.shared)
                .environmentObject(PushNotificationManager.shared)
                .environment(\.locale, localizationManager.locale)
                .onOpenURL { url in
                    TeamInviteCoordinator.shared.handleIncomingURL(url)
                }
                .task {
                    if UITestLaunchArgument.isEnabled {
                        return
                    }
                    await AuthService.shared.initialize()
                    await PushNotificationManager.shared.syncAfterBootstrap()
                }
        }
    }
}
