//
//  MainTabShell.swift
//  LeVestaire
//
//  Created by Corentin Robert on 16/06/2026.
//

import SwiftUI

struct MainTabShell: View {
    @EnvironmentObject private var authService: AuthService
    @StateObject private var viewModel = MainTabViewModel()

    @AppStorage("accountDeletionBannerDismissedUserId")
    private var dismissedBannerUserId = ""

    var body: some View {
        TabView {
            Tab(L10n.matches, systemImage: "sportscourt.fill") {
                mainTabRoot(title: L10n.matches) {
                    Matchs()
                }
            }

            Tab(L10n.team, systemImage: "person.3.fill") {
                mainTabRoot(title: L10n.team) {
                    Team()
                }
            }

            Tab(L10n.profile, systemImage: "person.crop.circle.fill") {
                mainTabRoot(title: L10n.profile) {
                    Profile()
                }
            }
        }
        .tabBarMinimizeBehavior(.onScrollDown)
        .onChange(of: authService.currentUser?.accountDeletion?.hasPendingDeletion) { _, hasPendingDeletion in
            if hasPendingDeletion != true {
                dismissedBannerUserId = ""
            }
        }
        .sheet(isPresented: $viewModel.showsNotificationCenter) {
            NavigationStack {
                NotificationsView()
                    .navigationTitle(L10n.notifications)
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .topBarTrailing) {
                            Button(L10n.close) {
                                viewModel.closeNotifications()
                            }
                        }
                    }
            }
        }
    }

    private var showsAccountDeletionBanner: Bool {
        guard let user = authService.currentUser,
              user.accountDeletion?.hasPendingDeletion == true else {
            return false
        }

        return dismissedBannerUserId != user.id
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
                    Button {
                        viewModel.openNotifications()
                    } label: {
                        Image(systemName: "bell.fill")
                    }
                    .accessibilityLabel(L10n.notifications)
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
}

#Preview {
    MainTabShell()
        .environmentObject(AuthService.shared)
}
