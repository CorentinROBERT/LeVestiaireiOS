//
//  ContentView.swift
//  LeVestaire
//
//  Created by Corentin Robert on 08/06/2026.
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var authService: AuthService
    @StateObject private var viewModel = ContentViewModel()

    var body: some View {
        Group {
            if !authService.isBootstrapComplete {
                bootstrapView
            } else if authService.isAuthenticated {
                if authService.requiresSportProfileCompletion {
                    sportProfileRoot
                } else {
                    authenticatedRoot
                }
            } else {
                unauthenticatedRoot
            }
        }
        .animation(.easeInOut, value: authService.isBootstrapComplete)
        .animation(.easeInOut, value: authService.isAuthenticated)
        .animation(.easeInOut, value: authService.requiresSportProfileCompletion)
        .animation(.easeInOut, value: viewModel.currentScreen)
    }

    private var bootstrapView: some View {
        ZStack {
            AuthScreenBackground()
                .ignoresSafeArea()
            ProgressView()
                .tint(AppPalette.Primary.main)
        }
    }

    private var unauthenticatedRoot: some View {
        Group {
            switch viewModel.currentScreen {
            case .landing:
                ULanding(
                    items: viewModel.landingItems,
                    onFinished: viewModel.completeOnboarding
                )
            case .login:
                Login()
            }
        }
    }

    private var authenticatedRoot: some View {
        MainTabShell()
    }

    private var sportProfileRoot: some View {
        NavigationStack {
            SportProfileView()
                .navigationTitle(L10n.sportProfileTitle)
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(AuthService.shared)
}
