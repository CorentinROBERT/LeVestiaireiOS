//
//  ContentView.swift
//  LeVestaire
//
//  Created by Corentin Robert on 08/06/2026.
//

import SwiftUI

private enum AppScreen {
    case landing
    case login
}

struct ContentView: View {
    @EnvironmentObject private var authService: AuthService
    @State private var currentScreen: AppScreen = OnboardingStore.shared.hasCompletedOnboarding ? .login : .landing

    var body: some View {
        Group {
            if authService.isAuthenticated {
                authenticatedRoot
            } else {
                unauthenticatedRoot
            }
        }
        .animation(.easeInOut, value: authService.isAuthenticated)
        .animation(.easeInOut, value: currentScreen)
    }

    private var unauthenticatedRoot: some View {
        Group {
            switch currentScreen {
            case .landing:
                ULanding(
                    items: landingItems,
                    onFinished: goToLoginPage
                )
            case .login:
                Login()
            }
        }
    }

    private var authenticatedRoot: some View {
        NavigationStack {
            Matchs()
                .navigationTitle("Matchs")
        }
    }

    private var landingItems: [CarouselItem] {
        [
            CarouselItem(
                title: "Gestion d'équipe",
                imageSource: "https://images.printkk.com/product/football-jersey-wjmqj-718.png",
                subtitle: "Organiser vos équipes et joueurs en toute simplicité",
                backgroundColor: .white
            ),
            CarouselItem(
                title: "Planification",
                imageSource: "https://www.radiofrance.fr/pikapi/images/c96aa7d9-e271-49da-99a3-df8d31dece21/1200x680",
                subtitle: "Planifier vos entrainements et match facilement",
                backgroundColor: .white
            ),
            CarouselItem(
                title: "Datas et Statistiques",
                imageSource: "https://static.onzemondial.com/8/2022/06/photo_article/784892/309937/1200-L-coupe-du-monde-2022-le-calendrier-complet-de-la-comptition.jpg",
                subtitle: "Superviser les statistiques de vos équipes",
                backgroundColor: .white
            ),
        ]
    }

    private func goToLoginPage() {
        OnboardingStore.shared.markOnboardingCompleted()
        currentScreen = .login
    }
}

#Preview {
    ContentView()
        .environmentObject(AuthService.shared)
}
