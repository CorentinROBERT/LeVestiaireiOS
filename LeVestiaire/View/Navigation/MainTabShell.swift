//
//  MainTabShell.swift
//  LeVestaire
//
//  Created by Corentin Robert on 16/06/2026.
//

import SwiftUI

struct MainTabShell: View {
    @EnvironmentObject private var authService: AuthService
    @EnvironmentObject private var teamInviteCoordinator: TeamInviteCoordinator
    @EnvironmentObject private var pushNotificationManager: PushNotificationManager
    @StateObject private var viewModel = MainTabViewModel()
    @StateObject private var notificationsViewModel = NotificationsViewModel()

    @AppStorage("accountDeletionBannerDismissedUserId")
    private var dismissedBannerUserId = ""

    var body: some View {
        Group {
            if UITestLaunchArgument.isEnabled {
                uiTestTabView
            } else {
                productionTabView
            }
        }
        .accessibilityIdentifier(AccessibilityID.Main.shell)
        .environmentObject(viewModel)
        .task {
            configureNotificationsViewModel()
            configurePushNotifications()
            guard !UITestLaunchArgument.isEnabled else { return }
            await viewModel.refreshUnreadCount()
            handlePendingPushNavigation()
        }
        .onChange(of: pushNotificationManager.pendingNavigation) { _, destination in
            guard destination != nil else { return }
            handlePendingPushNavigation()
        }
        .onChange(of: authService.currentUser?.accountDeletion?.hasPendingDeletion) { _, hasPendingDeletion in
            if hasPendingDeletion != true {
                dismissedBannerUserId = ""
            }
        }
        .onChange(of: viewModel.showsNotificationCenter) { _, isPresented in
            guard !isPresented else { return }
            Task { await viewModel.refreshUnreadCount() }
        }
        .onChange(of: teamInviteCoordinator.joinedTeamId) { _, teamId in
            guard let teamId else { return }
            viewModel.pendingTeamId = teamId
            viewModel.selectedTab = .team
            _ = teamInviteCoordinator.consumeJoinedTeamId()
        }
        .alert(
            L10n.team,
            isPresented: Binding(
                get: { teamInviteCoordinator.joinFeedbackMessage != nil },
                set: { if !$0 { teamInviteCoordinator.joinFeedbackMessage = nil } }
            )
        ) {
            Button(L10n.ok, role: .cancel) {}
        } message: {
            Text(teamInviteCoordinator.joinFeedbackMessage ?? "")
        }
        .sheet(isPresented: $viewModel.showsNotificationCenter) {
            NavigationStack {
                NotificationsView(viewModel: notificationsViewModel)
                    .navigationTitle(L10n.notifications)
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .topBarLeading) {
                            if notificationsViewModel.showsMarkAllAsRead {
                                Button {
                                    Task { await notificationsViewModel.markAllAsRead() }
                                } label: {
                                    if notificationsViewModel.isMarkingAllAsRead {
                                        ProgressView()
                                    } else {
                                        Text(L10n.text("markAllAsRead"))
                                    }
                                }
                                .disabled(notificationsViewModel.isMarkingAllAsRead)
                            }
                        }

                        ToolbarItem(placement: .topBarTrailing) {
                            Button(L10n.close) {
                                viewModel.closeNotifications()
                            }
                        }
                    }
            }
        }
    }

    private var productionTabView: some View {
        TabView(selection: $viewModel.selectedTab) {
            Tab(value: AppTab.matches) {
                mainTabRoot(title: L10n.matches) {
                    Matchs()
                }
            } label: {
                Label(L10n.matches, systemImage: "sportscourt.fill")
                    .accessibilityIdentifier(AccessibilityID.Tab.matches)
            }

            Tab(value: AppTab.team) {
                mainTabRoot(title: L10n.team) {
                    Team()
                }
            } label: {
                Label(L10n.team, systemImage: "person.3.fill")
                    .accessibilityIdentifier(AccessibilityID.Tab.team)
            }

            Tab(value: AppTab.profile) {
                mainTabRoot(title: L10n.profile) {
                    Profile()
                }
            } label: {
                Label(L10n.profile, systemImage: "person.crop.circle.fill")
                    .accessibilityIdentifier(AccessibilityID.Tab.profile)
            }
        }
        .modifier(MainTabShellTabBarBehavior())
    }

    private var uiTestTabView: some View {
        TabView(selection: $viewModel.selectedTab) {
            mainTabRoot(title: L10n.matches) {
                Matchs()
            }
            .tabItem {
                Label(L10n.matches, systemImage: "sportscourt.fill")
            }
            .tag(AppTab.matches)
            .accessibilityIdentifier(AccessibilityID.Tab.matches)

            mainTabRoot(title: L10n.team) {
                Team()
            }
            .tabItem {
                Label(L10n.team, systemImage: "person.3.fill")
            }
            .tag(AppTab.team)
            .accessibilityIdentifier(AccessibilityID.Tab.team)

            mainTabRoot(title: L10n.profile) {
                Profile()
            }
            .tabItem {
                Label(L10n.profile, systemImage: "person.crop.circle.fill")
            }
            .tag(AppTab.profile)
            .accessibilityIdentifier(AccessibilityID.Tab.profile)
        }
    }

    private var showsAccountDeletionBanner: Bool {
        guard let user = authService.currentUser,
              user.accountDeletion?.hasPendingDeletion == true else {
            return false
        }

        return dismissedBannerUserId != user.id
    }

    private func configureNotificationsViewModel() {
        notificationsViewModel.onUnreadCountChanged = { [weak viewModel] in
            await viewModel?.refreshUnreadCount()
        }
        notificationsViewModel.onNavigate = { [weak viewModel] destination in
            viewModel?.handleNotificationNavigation(destination)
        }
    }

    private func configurePushNotifications() {
        pushNotificationManager.onPushReceivedWhileActive = { [weak viewModel] in
            await viewModel?.refreshUnreadCount()
        }
    }

    private func handlePendingPushNavigation() {
        guard let destination = pushNotificationManager.consumePendingNavigation() else { return }
        viewModel.handleNotificationNavigation(destination)
    }

    private func mainTabRoot<Content: View>(
        title: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        NavigationStack {
            ZStack {
                AuthScreenBackground()
                    .ignoresSafeArea()

                content()
            }
            .navigationTitle(title)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    notificationToolbarButton
                }
            }
            .safeAreaInset(edge: .top, spacing: 0) {
                if showsAccountDeletionBanner,
                   let daysRemaining = authService.currentUser?.accountDeletion?.daysRemaining {
                    AccountDeletionNavigationBanner(daysRemaining: daysRemaining) {
                        dismissedBannerUserId = authService.currentUser?.id ?? ""
                    }
                }
            }
        }
    }

    @ViewBuilder
    private var notificationToolbarButton: some View {
        if UITestLaunchArgument.isEnabled {
            Button {
                viewModel.openNotifications()
            } label: {
                Image(systemName: "bell.fill")
            }
            .accessibilityLabel(L10n.notifications)
            .accessibilityIdentifier(AccessibilityID.Main.notificationsButton)
        } else if viewModel.unreadCount > 0 {
            Button {
                viewModel.openNotifications()
            } label: {
                Image(systemName: "bell.fill")
            }
            .badge(viewModel.unreadCount > 99 ? "99+" : "\(viewModel.unreadCount)")
            .accessibilityLabel(L10n.notifications)
            .accessibilityIdentifier(AccessibilityID.Main.notificationsButton)
        } else {
            Button {
                viewModel.openNotifications()
            } label: {
                Image(systemName: "bell.fill")
            }
            .accessibilityLabel(L10n.notifications)
            .accessibilityIdentifier(AccessibilityID.Main.notificationsButton)
        }
    }
}

private struct MainTabShellTabBarBehavior: ViewModifier {
    func body(content: Content) -> some View {
        if UITestLaunchArgument.isEnabled {
            content
        } else {
            content.tabBarMinimizeBehavior(.onScrollDown)
        }
    }
}

#Preview {
    MainTabShell()
        .environmentObject(AuthService.shared)
        .environmentObject(TeamInviteCoordinator.shared)
        .environmentObject(PushNotificationManager.shared)
}
