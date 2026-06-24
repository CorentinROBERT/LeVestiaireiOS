//
//  PushNotificationManager.swift
//  LeVestaire
//

import Combine
import FirebaseMessaging
import Foundation
import UIKit
import UserNotifications

@MainActor
final class PushNotificationManager: ObservableObject {
    static let shared = PushNotificationManager()

    @Published private(set) var pendingNavigation: NotificationNavigationDestination?
    @Published private(set) var authorizationGranted = false

    var onPushReceivedWhileActive: (() async -> Void)?

    private var fcmToken: String?
    private var lastRegisteredToken: String?
    private var hasRequestedAuthorization = false

    private let deviceTokenService: DeviceTokenService
    private let authService: AuthService
    private let remoteSettings: RemoteSettingsService
    private var cancellables = Set<AnyCancellable>()

    private init(
        deviceTokenService: DeviceTokenService,
        authService: AuthService,
        remoteSettings: RemoteSettingsService
    ) {
        self.deviceTokenService = deviceTokenService
        self.authService = authService
        self.remoteSettings = remoteSettings

        authService.$isAuthenticated
            .removeDuplicates()
            .sink { [weak self] isAuthenticated in
                guard let self else { return }
                Task { @MainActor in
                    if isAuthenticated {
                        await self.syncTokenWithBackendIfNeeded()
                    } else {
                        await self.unregisterFromBackendIfNeeded()
                    }
                }
            }
            .store(in: &cancellables)
    }

    convenience init() {
        self.init(
            deviceTokenService: .shared,
            authService: .shared,
            remoteSettings: .shared
        )
    }

    var isPushEnabled: Bool {
        remoteSettings.settings.featureFlag(\.pushEnabled, default: true)
    }

    func configure(application: UIApplication) {
        guard isPushEnabled else { return }

        Task {
            await requestAuthorizationIfNeeded(application: application)
            await refreshAuthorizationStatus()
            if authService.isAuthenticated {
                await syncTokenWithBackendIfNeeded()
            }
        }
    }

    func setAPNSToken(_ deviceToken: Data) {
        Messaging.messaging().apnsToken = deviceToken
        Task {
            await refreshFCMToken()
        }
    }

    func updateFCMToken(_ token: String?) {
        let trimmed = token?.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let trimmed, !trimmed.isEmpty else { return }

        fcmToken = trimmed
        Task {
            await syncTokenWithBackendIfNeeded()
        }
    }

    func handleNotificationTap(userInfo: [AnyHashable: Any]) {
        guard let destination = NotificationDeepLinkParser.destination(from: userInfo) else {
            return
        }
        pendingNavigation = destination
    }

    func handleForegroundNotification(userInfo: [AnyHashable: Any]) {
        Task {
            await onPushReceivedWhileActive?()
        }
    }

    func consumePendingNavigation() -> NotificationNavigationDestination? {
        defer { pendingNavigation = nil }
        return pendingNavigation
    }

    func clearPendingNavigation() {
        pendingNavigation = nil
    }

    func syncAfterBootstrap() async {
        guard isPushEnabled else { return }
        await refreshAuthorizationStatus()
        if Messaging.messaging().apnsToken != nil {
            await refreshFCMToken()
        }
        if authService.isAuthenticated {
            await syncTokenWithBackendIfNeeded()
        }
    }

    func sendTestPushNotification() async throws {
        _ = try await deviceTokenService.sendTestPushNotification()
    }

    private func requestAuthorizationIfNeeded(application: UIApplication) async {
        guard !hasRequestedAuthorization else { return }
        hasRequestedAuthorization = true

        do {
            let granted = try await UNUserNotificationCenter.current().requestAuthorization(
                options: [.alert, .badge, .sound]
            )
            authorizationGranted = granted
            if granted {
                application.registerForRemoteNotifications()
            }
        } catch {
            authorizationGranted = false
        }
    }

    private func refreshAuthorizationStatus() async {
        let settings = await UNUserNotificationCenter.current().notificationSettings()
        authorizationGranted = settings.authorizationStatus == .authorized
            || settings.authorizationStatus == .provisional
    }

    private func refreshFCMToken() async {
        guard authorizationGranted else { return }

        do {
            let token = try await Messaging.messaging().token()
            updateFCMToken(token)
        } catch {
            return
        }
    }

    private func syncTokenWithBackendIfNeeded() async {
        guard isPushEnabled,
              authService.isAuthenticated,
              let token = fcmToken,
              token != lastRegisteredToken else {
            return
        }

        do {
            try await deviceTokenService.registerFCMToken(token)
            lastRegisteredToken = token
        } catch {
            return
        }
    }

    private func unregisterFromBackendIfNeeded() async {
        guard let token = lastRegisteredToken ?? fcmToken else { return }

        do {
            try await deviceTokenService.unregisterFCMToken(token)
        } catch {
            // Best effort on logout.
        }

        lastRegisteredToken = nil
    }
}
