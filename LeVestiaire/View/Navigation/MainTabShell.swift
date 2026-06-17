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
            Tab("Matchs", systemImage: "sportscourt.fill") {
                mainTabRoot(title: "Matchs") {
                    Matchs()
                }
            }

            Tab("Équipe", systemImage: "person.3.fill") {
                mainTabRoot(title: "Équipe") {
                    Team()
                }
            }

            Tab("Profil", systemImage: "person.crop.circle.fill") {
                mainTabRoot(title: "Profil") {
                    Profile()
                }
            }
        }
        .tabBarMinimizeBehavior(.onScrollDown)
        .sheet(isPresented: $viewModel.showsNotificationCenter) {
            NavigationStack {
                NotificationsView()
                    .navigationTitle("Notifications")
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .topBarTrailing) {
                            Button("Fermer") {
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
