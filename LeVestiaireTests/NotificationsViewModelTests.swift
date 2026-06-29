//
//  NotificationsViewModelTests.swift
//  LeVestiaireTests
//

import Foundation
import Testing
@testable import LeVestiaire

@MainActor
struct NotificationsViewModelTests {
  @Test
  func initialize_loadsNotifications() async throws {
    let unread = AppNotification(
      id: "n-1",
      title: "Match",
      body: "Nouveau match",
      type: .matchCreated,
      isRead: false,
      createdAt: Date()
    )
    let service = MockNotificationService()
    service.fetchNotificationsHandler = { _ in
      try ViewModelTestFixtures.notificationListResponse(notifications: [unread])
    }
    let viewModel = NotificationsViewModel(notificationService: service)

    await viewModel.initialize()

    #expect(viewModel.notifications.count == 1)
    #expect(viewModel.isLoading == false)
  }

  @Test
  func showsMarkAllAsRead_whenUnreadNotificationsExist() async throws {
    let unread = AppNotification(
      id: "n-1",
      title: "Match",
      body: "Body",
      type: .matchCreated,
      isRead: false,
      createdAt: Date()
    )
    let service = MockNotificationService()
    service.fetchNotificationsHandler = { _ in
      try ViewModelTestFixtures.notificationListResponse(notifications: [unread])
    }
    let viewModel = NotificationsViewModel(notificationService: service)
    await viewModel.initialize()

    #expect(viewModel.showsMarkAllAsRead)
  }

  @Test
  func markAllAsRead_updatesLocalState() async throws {
    let unread = AppNotification(
      id: "n-1",
      title: "Match",
      body: "Body",
      type: .matchCreated,
      isRead: false,
      createdAt: Date()
    )
    let service = MockNotificationService()
    service.fetchNotificationsHandler = { _ in
      try ViewModelTestFixtures.notificationListResponse(notifications: [unread])
    }
    var unreadCountRefreshCount = 0
    let viewModel = NotificationsViewModel(notificationService: service)
    viewModel.onUnreadCountChanged = {
      unreadCountRefreshCount += 1
    }
    await viewModel.initialize()

    await viewModel.markAllAsRead()

    #expect(viewModel.notifications.first?.isRead == true)
    #expect(viewModel.toastMessage != nil)
    #expect(unreadCountRefreshCount == 1)
  }

  @Test
  func handleSelection_navigatesToMatch() async throws {
    let notification = AppNotification(
      id: "n-2",
      title: "Match",
      body: "Body",
      type: .matchCreated,
      isRead: true,
      metadata: NotificationMetadata(matchId: "match-77"),
      createdAt: Date()
    )
    let service = MockNotificationService()
    service.fetchNotificationsHandler = { _ in
      try ViewModelTestFixtures.notificationListResponse(notifications: [notification])
    }
    let viewModel = NotificationsViewModel(notificationService: service)
    var destination: NotificationNavigationDestination?
    viewModel.onNavigate = { destination = $0 }
    await viewModel.initialize()

    await viewModel.handleSelection(for: notification)

    #expect(destination == .match("match-77"))
  }

  @Test
  func applyFilter_reloadsNotifications() async throws {
    let service = MockNotificationService()
    var lastFilter: NotificationFilter?
    service.fetchNotificationsHandler = { criteria in
      lastFilter = criteria.filter
      return try ViewModelTestFixtures.notificationListResponse()
    }
    let viewModel = NotificationsViewModel(notificationService: service)
    await viewModel.initialize()

    await viewModel.applyFilter(.unread)

    #expect(viewModel.filter == .unread)
    #expect(lastFilter == .unread)
  }
}
