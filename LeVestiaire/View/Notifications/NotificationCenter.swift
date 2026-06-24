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
                ProgressView(L10n.loading)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if let errorMessage = viewModel.errorMessage, viewModel.notifications.isEmpty {
                errorState(message: errorMessage)
            } else {
                notificationsList
            }
        }
        .overlay(alignment: .bottom) {
            if let toastMessage = viewModel.toastMessage {
                TeamToastBanner(message: toastMessage)
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
        ScrollView(showsIndicators: false) {
            LazyVStack(spacing: 16) {
                filterPicker

                if viewModel.notifications.isEmpty {
                    emptyState
                } else {
                    ForEach(viewModel.notifications) { notification in
                        NotificationRowView(
                            notification: notification,
                            isMarkingRead: viewModel.isMarkingRead(notification.id)
                        ) {
                            Task {
                                await viewModel.handleSelection(for: notification)
                            }
                        }
                        .task {
                            await viewModel.loadNextPageIfNeeded(currentNotification: notification)
                        }
                    }

                    paginationFooter
                }
            }
            .padding(20)
        }
        .refreshable {
            await viewModel.refreshFromPullToRefresh()
        }
    }

    private var filterPicker: some View {
        Picker(L10n.filter, selection: Binding(
            get: { viewModel.filter },
            set: { newValue in
                Task { await viewModel.applyFilter(newValue) }
            }
        )) {
            ForEach(NotificationFilter.allCases) { filter in
                Text(filter.localizedTitle).tag(filter)
            }
        }
        .pickerStyle(.segmented)
    }

    private var emptyState: some View {
        TeamEmptyState(
            icon: viewModel.filter == .unread ? "bell.badge" : "bell.slash",
            title: viewModel.filter == .unread
                ? L10n.text("noUnreadNotifications")
                : L10n.noNotifications,
            message: viewModel.filter == .unread
                ? nil
                : L10n.noNotificationsDescription
        )
    }

    private var paginationFooter: some View {
        VStack(spacing: 8) {
            if viewModel.isLoadingMore {
                ProgressView()
            } else if viewModel.showsEndOfListMessage {
                Text(L10n.scrollToLoadMore)
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
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
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
                                if isMarkingRead {
                                    ProgressView()
                                        .controlSize(.small)
                                } else if !notification.isRead {
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
        }
        .buttonStyle(.plain)
        .opacity(notification.isRead ? 0.88 : 1)
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
#endif
