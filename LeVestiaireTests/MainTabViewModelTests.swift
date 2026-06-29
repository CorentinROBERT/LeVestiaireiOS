//
//  MainTabViewModelTests.swift
//  LeVestiaireTests
//

import Foundation
import Testing
@testable import LeVestiaire

@MainActor
struct MainTabViewModelTests {
  @Test
  func openAndCloseNotifications_toggleSheet() {
    let viewModel = MainTabViewModel(notificationService: MockNotificationService())

    viewModel.openNotifications()
    #expect(viewModel.showsNotificationCenter)

    viewModel.closeNotifications()
    #expect(viewModel.showsNotificationCenter == false)
  }

  @Test
  func refreshUnreadCount_updatesBadge() async {
    let service = MockNotificationService()
    service.fetchUnreadCountHandler = { 7 }
    let viewModel = MainTabViewModel(notificationService: service)

    await viewModel.refreshUnreadCount()

    #expect(viewModel.unreadCount == 7)
  }

  @Test
  func handleNotificationNavigation_setsPendingMatchAndTab() {
    let viewModel = MainTabViewModel(notificationService: MockNotificationService())

    viewModel.handleNotificationNavigation(.match("match-42"))

    #expect(viewModel.pendingMatchId == "match-42")
    #expect(viewModel.selectedTab == .matches)
    #expect(viewModel.showsNotificationCenter == false)
  }

  @Test
  func handleNotificationNavigation_setsPendingTeamAndTab() {
    let viewModel = MainTabViewModel(notificationService: MockNotificationService())

    viewModel.handleNotificationNavigation(.team("team-99"))

    #expect(viewModel.pendingTeamId == "team-99")
    #expect(viewModel.selectedTab == .team)
  }

  @Test
  func clearPendingNavigation_resetsIds() {
    let viewModel = MainTabViewModel(notificationService: MockNotificationService())
    viewModel.pendingMatchId = "match-1"
    viewModel.pendingTeamId = "team-1"

    viewModel.clearPendingMatchNavigation()
    viewModel.clearPendingTeamNavigation()

    #expect(viewModel.pendingMatchId == nil)
    #expect(viewModel.pendingTeamId == nil)
  }
}
