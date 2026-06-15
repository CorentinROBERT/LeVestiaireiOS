//
//  ContentView.swift
//  LeVestaire
//
//  Created by Corentin Robert on 08/06/2026.
//

import SwiftUI
import SwiftData

private enum AppScreen {
    case landing
    case login
}

struct ContentView: View {

    @State private var currentScreen: AppScreen = .landing

    var body: some View {
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
        .animation(.easeInOut, value: currentScreen)
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
        currentScreen = .login
    }
}

#Preview {
    ContentView()
}
