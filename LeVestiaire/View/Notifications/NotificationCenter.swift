//
//  NotificationCenter.swift
//  LeVestaire
//
//  Created by Corentin Robert on 15/06/2026.
//

import SwiftUI

struct NotificationsView: View {
    @ObservedObject var viewModel: NotificationsViewModel

    var body: some View {
        Group {
            if viewModel.isLoading, viewModel.notifications.isEmpty {
                ProgressView(L10n.notificationsLoading)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if let errorMessage = viewModel.errorMessage, viewModel.notifications.isEmpty {
                errorState(message: errorMessage)
            } else {
                notificationsList
            }
        }
        .overlay(alignment: .bottom) {
            if let toastMessage = viewModel.toastMessage {
                TeamToastBanner(
                    message: toastMessage,
                    style: viewModel.toastIsError ? .error : .success
                )
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .animation(.easeInOut(duration: 0.25), value: viewModel.toastMessage)
        .task {
            await viewModel.initialize()
        }
        .onChange(of: viewModel.toastMessage) { _, message in
            guard message != nil else { return }
            Task {
                try? await Task.sleep(nanoseconds: 2_500_000_000)
                if viewModel.toastMessage == message {
                    viewModel.toastMessage = nil
                }
            }
        }
    }

    private var notificationsList: some View {
        List {
            Section {
                filterPicker
                    .listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 12, trailing: 0))
                    .listRowBackground(Color.clear)
                    .listRowSeparator(.hidden)
            }

            if viewModel.notifications.isEmpty {
                Section {
                    emptyState
                        .listRowInsets(EdgeInsets())
                        .listRowBackground(Color.clear)
                        .listRowSeparator(.hidden)
                }
            } else {
                Section {
                    ForEach(viewModel.notifications) { notification in
                        notificationRow(for: notification)
                            .listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 16, trailing: 0))
                            .listRowBackground(Color.clear)
                            .listRowSeparator(.hidden)
                    }

                    paginationFooter
                        .listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 8, trailing: 0))
                        .listRowBackground(Color.clear)
                        .listRowSeparator(.hidden)
                }
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .contentMargins(.horizontal, 20, for: .scrollContent)
        .refreshable {
            await viewModel.refreshFromPullToRefresh()
        }
    }

    @ViewBuilder
    private func notificationRow(for notification: AppNotification) -> some View {
        NotificationRowView(
            notification: notification,
            isMarkingRead: viewModel.isMarkingRead(notification.id),
            isArchiving: viewModel.isArchiving(notification.id)
        ) {
            Task {
                await viewModel.handleSelection(for: notification)
            }
        }
        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
            if viewModel.filter == .archived {
                Button {
                    Task {
                        await viewModel.unarchiveNotification(notification)
                    }
                } label: {
                    Label(L10n.text("unarchiveNotification"), systemImage: "tray.and.arrow.up.fill")
                }
                .tint(AppPalette.Primary.main)
            } else {
                Button {
                    Task {
                        await viewModel.archiveNotification(notification)
                    }
                } label: {
                    Label(L10n.text("archiveNotification"), systemImage: "archivebox.fill")
                }
                .tint(AppPalette.Primary.main)
            }
        }
        .contextMenu {
            if viewModel.filter == .archived {
                Button {
                    Task {
                        await viewModel.unarchiveNotification(notification)
                    }
                } label: {
                    Label(L10n.text("unarchiveNotification"), systemImage: "tray.and.arrow.up")
                }
            } else {
                Button {
                    Task {
                        await viewModel.archiveNotification(notification)
                    }
                } label: {
                    Label(L10n.text("archiveNotification"), systemImage: "archivebox")
                }
            }
        }
        .task {
            await viewModel.loadNextPageIfNeeded(currentNotification: notification)
        }
    }

    private var filterPicker: some View {
        USegmentedPicker(
            title: L10n.filter,
            selection: Binding(
                get: { viewModel.filter },
                set: { newValue in
                    Task { await viewModel.applyFilter(newValue) }
                }
            )
        ) {
            ForEach(NotificationFilter.allCases) { filter in
                Text(filter.localizedTitle).tag(filter)
            }
        }
    }

    private var emptyState: some View {
        TeamEmptyState(
            icon: emptyStateIcon,
            title: emptyStateTitle,
            message: emptyStateMessage
        )
    }

    private var emptyStateIcon: String {
        switch viewModel.filter {
        case .all:
            return "bell.slash"
        case .unread:
            return "bell.badge"
        case .archived:
            return "archivebox"
        }
    }

    private var emptyStateTitle: String {
        switch viewModel.filter {
        case .all:
            return L10n.noNotifications
        case .unread:
            return L10n.text("noUnreadNotifications")
        case .archived:
            return L10n.text("noArchivedNotifications")
        }
    }

    private var emptyStateMessage: String? {
        switch viewModel.filter {
        case .all:
            return L10n.noNotificationsDescription
        case .unread, .archived:
            return nil
        }
    }

    private var paginationFooter: some View {
        VStack(spacing: 8) {
            if viewModel.isLoadingMore {
                ProgressView()
            } else if viewModel.showsEndOfListMessage {
                Text(L10n.allNotificationsLoaded)
                    .font(.caption)
                    .foregroundStyle(AppPalette.Neutral.textTertiary)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
    }

    private func errorState(message: String) -> some View {
        ScrollView {
            VStack(spacing: 16) {
                filterPicker

                UCard(icon: "exclamationmark.triangle.fill", iconTint: AppPalette.Semantic.error) {
                    VStack(spacing: 12) {
                        Text(message)
                            .font(.subheadline)
                            .foregroundStyle(AppPalette.Neutral.textSecondary)
                            .multilineTextAlignment(.center)

                        UButton(
                            text: L10n.retry,
                            textColor: AppPalette.Primary.onMain,
                            backgroundColor: AppPalette.Primary.main,
                            cornerRadius: 12,
                            onPress: {
                                Task { await viewModel.refreshFromPullToRefresh() }
                            }
                        )
                    }
                    .frame(maxWidth: .infinity)
                }
            }
            .padding(20)
        }
    }
}

private struct NotificationRowView: View {
    let notification: AppNotification
    let isMarkingRead: Bool
    let isArchiving: Bool
    let onTap: () -> Void

    var body: some View {
        UCard(cornerRadius: 16, padding: 16) {
            HStack(alignment: .top, spacing: 12) {
                notificationVisual

                VStack(alignment: .leading, spacing: 6) {
                    HStack(alignment: .firstTextBaseline) {
                        Text(notification.title)
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(AppPalette.Neutral.textPrimary)
                            .multilineTextAlignment(.leading)

                        Spacer(minLength: 8)

                        HStack(spacing: 6) {
                            if isMarkingRead || isArchiving {
                                ProgressView()
                                    .controlSize(.small)
                            } else if !notification.isRead, !notification.isArchived {
                                Circle()
                                    .fill(AppPalette.Secondary.coral)
                                    .frame(width: 10, height: 10)
                                    .accessibilityLabel(L10n.text("unread"))
                            }

                            Text(notification.relativeTimestamp)
                                .font(.caption)
                                .foregroundStyle(AppPalette.Neutral.textTertiary)
                        }
                    }

                    Text(notification.subtitleLabel)
                        .font(.caption.weight(.medium))
                        .foregroundStyle(AppPalette.Primary.muted)

                    if !notification.body.isEmpty {
                        Text(notification.body)
                            .font(.subheadline)
                            .foregroundStyle(AppPalette.Neutral.textSecondary)
                            .multilineTextAlignment(.leading)
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .contentShape(Rectangle())
        .onTapGesture(perform: onTap)
        .opacity(notification.isRead ? 0.88 : 1)
        .accessibilityAddTraits(.isButton)
    }

    @ViewBuilder
    private var notificationVisual: some View {
        if let imageURL = notification.resolvedImageURL {
            CachedRemoteImage(url: imageURL) { image in
                image
                    .resizable()
                    .scaledToFill()
            } placeholder: {
                Image(systemName: notification.type.iconName)
                    .font(.title3)
                    .foregroundStyle(AppPalette.Primary.muted)
            }
            .frame(width: 44, height: 44)
            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        } else {
            Image(systemName: notification.type.iconName)
                .font(.title3)
                .foregroundStyle(notification.isRead ? AppPalette.Neutral.textTertiary : AppPalette.Primary.main)
                .frame(width: 28)
        }
    }
}

#if DEBUG
#Preview("All") {
    NavigationStack {
        NotificationsView(viewModel: .preview())
            .navigationTitle(L10n.notifications)
    }
}

#Preview("Unread filter") {
    NavigationStack {
        NotificationsView(viewModel: .preview(unreadOnly: true))
            .navigationTitle(L10n.notifications)
    }
}
#Preview("Archived filter") {
    NavigationStack {
        NotificationsView(viewModel: .previewArchived())
            .navigationTitle(L10n.notifications)
    }
}
#endif
