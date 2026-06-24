//
//  NotificationsViewModel.swift
//  LeVestaire
//

import Combine
import Foundation

enum NotificationNavigationDestination: Equatable {
    case match(String)
    case team(String)
    case externalURL(URL)
}

@MainActor
final class NotificationsViewModel: ObservableObject {
    @Published private(set) var notifications: [AppNotification] = []
    @Published var filter: NotificationFilter = .all
    @Published private(set) var isLoading = false
    @Published private(set) var isLoadingMore = false
    @Published private(set) var isRefreshing = false
    @Published private(set) var isMarkingAllAsRead = false
    @Published private(set) var errorMessage: String?
    @Published var toastMessage: String?
    @Published private(set) var markingReadNotificationIds: Set<String> = []

    private let notificationService: NotificationService
    private var currentPage = 1
    private var hasReachedMax = false
    private var loadGeneration = 0
    private var totalItems = 0
    let pullToRefreshTask = PullToRefreshTask()

    var showsMarkAllAsRead: Bool {
        notifications.contains { !$0.isRead }
    }

    var showsEndOfListMessage: Bool {
        hasReachedMax && !notifications.isEmpty
    }

    var onUnreadCountChanged: (() async -> Void)?
    var onNavigate: ((NotificationNavigationDestination) -> Void)?

    init(notificationService: NotificationService) {
        self.notificationService = notificationService
    }

    convenience init() {
        self.init(notificationService: NotificationService.shared)
    }

    func initialize() async {
        guard notifications.isEmpty else { return }
        await loadNotifications(page: 1, append: false)
    }

    func refresh() async {
        await executeRefresh()
    }

    func refreshFromPullToRefresh() async {
        await pullToRefreshTask.perform { [weak self] in
            await self?.executeRefresh()
        }
    }

    private func executeRefresh() async {
        await loadNotifications(page: 1, append: false, isRefresh: true)
        await onUnreadCountChanged?()
    }

    func applyFilter(_ filter: NotificationFilter) async {
        guard self.filter != filter else { return }
        self.filter = filter
        await loadNotifications(page: 1, append: false)
    }

    func loadNextPageIfNeeded(currentNotification: AppNotification) async {
        guard currentNotification.id == notifications.last?.id else { return }
        await loadNextPage()
    }

    func loadNextPage() async {
        guard !isLoading, !isLoadingMore, !isRefreshing, !hasReachedMax else { return }
        await loadNotifications(page: currentPage + 1, append: true)
    }

    func markAllAsRead() async {
        guard showsMarkAllAsRead, !isMarkingAllAsRead else { return }

        isMarkingAllAsRead = true
        defer { isMarkingAllAsRead = false }

        do {
            try await notificationService.markAllAsRead()
            notifications = notifications.map { $0.markingAsRead() }
            toastMessage = L10n.text("allNotificationsMarkedAsReadSuccess")
            await onUnreadCountChanged?()
        } catch let error as NotificationServiceError {
            toastMessage = error.errorDescription
        } catch {
            toastMessage = error.localizedDescription
        }
    }

    func handleSelection(for notification: AppNotification) async {
        if !notification.isRead {
            await markAsRead(notification)
        }
        navigate(for: notification)
    }

    func isMarkingRead(_ notificationId: String) -> Bool {
        markingReadNotificationIds.contains(notificationId)
    }

    private func markAsRead(_ notification: AppNotification) async {
        guard !markingReadNotificationIds.contains(notification.id) else { return }

        markingReadNotificationIds.insert(notification.id)
        defer { markingReadNotificationIds.remove(notification.id) }

        do {
            try await notificationService.markAsRead(notificationId: notification.id)
            if let index = notifications.firstIndex(where: { $0.id == notification.id }) {
                notifications[index] = notifications[index].markingAsRead()
            }
            if filter == .unread {
                notifications.removeAll { $0.id == notification.id }
            }
            await onUnreadCountChanged?()
        } catch let error as NotificationServiceError {
            toastMessage = error.errorDescription
        } catch {
            toastMessage = error.localizedDescription
        }
    }

    private func navigate(for notification: AppNotification) {
        if let matchId = notification.resolvedMatchId {
            onNavigate?(.match(matchId))
            return
        }

        if let teamId = notification.resolvedTeamId {
            onNavigate?(.team(teamId))
            return
        }

        if let url = notification.resolvedExternalURL {
            onNavigate?(.externalURL(url))
        }
    }

    private func loadNotifications(page: Int, append: Bool, isRefresh: Bool = false) async {
        loadGeneration += 1
        let generation = loadGeneration

        if append {
            isLoadingMore = true
        } else if isRefresh, !notifications.isEmpty {
            isRefreshing = true
        } else {
            isLoading = true
            errorMessage = nil
        }

        defer {
            if generation == loadGeneration {
                isLoading = false
                isLoadingMore = false
                isRefreshing = false
            }
        }

        do {
            let criteria = NotificationFetchCriteria(page: page, filter: filter)
            let response = try await notificationService.fetchNotifications(criteria: criteria)
            guard generation == loadGeneration else { return }

            let fetchedNotifications = response.notifications.filter { !$0.id.isEmpty }

            if append {
                let existingIDs = Set(notifications.map(\.id))
                let newNotifications = fetchedNotifications.filter { !existingIDs.contains($0.id) }
                notifications.append(contentsOf: newNotifications)
            } else {
                notifications = fetchedNotifications
            }

            currentPage = response.pageInfo?.page ?? page
            totalItems = response.pageInfo?.total ?? notifications.count
            hasReachedMax = !(response.pageInfo?.hasNextPage ?? false)
            errorMessage = nil
        } catch {
            guard generation == loadGeneration else { return }
            guard !TaskCancellation.isError(error) else { return }

            if !append, notifications.isEmpty {
                if let serviceError = error as? NotificationServiceError {
                    errorMessage = serviceError.errorDescription
                } else {
                    errorMessage = error.localizedDescription
                }
            } else if append {
                toastMessage = L10n.text("errorLoadingMoreNotifications")
            }
        }
    }
}

#if DEBUG
extension NotificationsViewModel {
    static func preview(unreadOnly: Bool = false) -> NotificationsViewModel {
        let viewModel = NotificationsViewModel()
        viewModel.notifications = unreadOnly
            ? [.previewUnread]
            : [.previewUnread, .previewRead]
        return viewModel
    }
}
#endif
