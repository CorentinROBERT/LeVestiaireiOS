//
//  MainTabViewModel.swift
//  LeVestaire
//
//  Created by Corentin Robert on 16/06/2026.
//

import Combine
import Foundation
import UIKit

enum AppTab: Hashable {
    case matches
    case team
    case profile
}

@MainActor
final class MainTabViewModel: ObservableObject {
    @Published var showsNotificationCenter = false
    @Published var selectedTab: AppTab = .matches
    @Published private(set) var unreadCount = 0
    @Published var pendingMatchId: String?
    @Published var pendingTeamId: String?

    private let notificationService: NotificationService

    init(notificationService: NotificationService) {
        self.notificationService = notificationService
    }

    convenience init() {
        self.init(notificationService: .shared)
    }

    func openNotifications() {
        showsNotificationCenter = true
    }

    func closeNotifications() {
        showsNotificationCenter = false
    }

    func refreshUnreadCount() async {
        do {
            unreadCount = max(0, try await notificationService.fetchUnreadCount())
        } catch {
            // Keep the previous badge value on transient failures.
        }
    }

    func handleNotificationNavigation(_ destination: NotificationNavigationDestination) {
        closeNotifications()

        switch destination {
        case .match(let matchId):
            pendingMatchId = matchId
            selectedTab = .matches
        case .team(let teamId):
            pendingTeamId = teamId
            selectedTab = .team
        case .externalURL(let url):
            UIApplication.shared.open(url)
        }
    }

    func clearPendingMatchNavigation() {
        pendingMatchId = nil
    }

    func clearPendingTeamNavigation() {
        pendingTeamId = nil
    }
}
