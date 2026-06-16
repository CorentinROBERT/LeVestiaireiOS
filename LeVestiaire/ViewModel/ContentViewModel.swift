//
//  ContentViewModel.swift
//  LeVestaire
//
//  Created by Corentin Robert on 16/06/2026.
//

import Combine
import Foundation
import SwiftUI

@MainActor
final class ContentViewModel: ObservableObject {
    enum AppScreen {
        case landing
        case login
    }

    @Published private(set) var currentScreen: AppScreen

    private let onboardingStore: OnboardingStore

    init(onboardingStore: OnboardingStore) {
        self.onboardingStore = onboardingStore
        currentScreen = onboardingStore.hasCompletedOnboarding ? .login : .landing
    }

    convenience init() {
        self.init(onboardingStore: OnboardingStore.shared)
    }

    var landingItems: [CarouselItem] {
        [
            .welcome(
                appName: "Le Vestiaire",
                tagline: "Ton vestiaire digital, partout avec toi"
            ),
            CarouselItem(
                title: "Gestion d'équipe",
                imageSource: "https://images.printkk.com/product/football-jersey-wjmqj-718.png",
                subtitle: "Créez votre effectif, invitez vos joueurs et gardez leurs profils à jour",
                backgroundColor: .white
            ),
            CarouselItem(
                title: "Planification",
                imageSource: "https://www.radiofrance.fr/pikapi/images/c96aa7d9-e271-49da-99a3-df8d31dece21/1200x680",
                subtitle: "Planifier vos championnats, coupes et matchs facilement",
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

    func completeOnboarding() {
        onboardingStore.markOnboardingCompleted()
        currentScreen = .login
    }
}
