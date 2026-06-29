//
//  ContentView.swift
//  LeVestaire
//
//  Created by Corentin Robert on 08/06/2026.
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var authService: AuthService
    @EnvironmentObject private var localizationManager: LocalizationManager
    @EnvironmentObject private var teamInviteCoordinator: TeamInviteCoordinator
    @StateObject private var viewModel = ContentViewModel()
    @ObservedObject private var remoteSettings = RemoteSettingsService.shared

    var body: some View {
        ZStack {
            rootContent

            if remoteSettings.isMaintenanceMode {
                MaintenanceView(
                    message: remoteSettings.localizedMaintenanceMessage(
                        language: localizationManager.language
                    )
                )
                .transition(.opacity)
            } else if remoteSettings.requiresForceUpdate {
                ForceUpdateView(
                    message: remoteSettings.localizedForceUpdateMessage(
                        language: localizationManager.language
                    ),
                    storeURL: remoteSettings.forceUpdateStoreURL
                )
                .transition(.opacity)
            }
        }
        .animation(.easeInOut, value: remoteSettings.isMaintenanceMode)
        .animation(.easeInOut, value: remoteSettings.requiresForceUpdate)
        .task {
            if UITestLaunchArgument.isEnabled {
                UITestAppConfigurator.configureIfNeeded(authService: authService)
                return
            }
            remoteSettings.start()
        }
        .task(id: authService.isBootstrapComplete) {
            await handlePendingTeamInviteIfNeeded()
        }
        .onChange(of: teamInviteCoordinator.hasPendingCode) { _, hasCode in
            guard hasCode else { return }
            viewModel.completeOnboarding()
            Task { await teamInviteCoordinator.validatePendingCode() }
        }
    }

    private func handlePendingTeamInviteIfNeeded() async {
        guard authService.isBootstrapComplete, teamInviteCoordinator.hasPendingCode else { return }

        if !authService.isAuthenticated {
            viewModel.completeOnboarding()
        }

        await teamInviteCoordinator.validatePendingCode()

        if authService.isAuthenticated {
            _ = await teamInviteCoordinator.joinPendingTeamIfNeeded()
        }
    }

    @ViewBuilder
    private var rootContent: some View {
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
            VStack {
                Image(systemName: "pencil.and.list.clipboard")
                    .font(.system(size: 48))
                    .foregroundStyle(AppPalette.Primary.main)
                UText(text: L10n.loading)
                ProgressView()
                    .tint(AppPalette.Primary.main)
            }
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
        .environmentObject(LocalizationManager.shared)
        .environmentObject(TeamInviteCoordinator.shared)
}
