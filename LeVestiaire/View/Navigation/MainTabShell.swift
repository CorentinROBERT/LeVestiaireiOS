//
//  MainTabShell.swift
//  LeVestaire
//
//  Created by Corentin Robert on 16/06/2026.
//

import SwiftUI

struct MainTabShell: View {
    @StateObject private var viewModel = MainTabViewModel()

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
                    .accessibilityLabel("Notifications")
                }
            }
        }
    }
}

#Preview {
    MainTabShell()
}
