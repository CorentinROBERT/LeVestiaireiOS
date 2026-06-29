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

    private let onboardingStore: any OnboardingStoring

    init(onboardingStore: any OnboardingStoring) {
        self.onboardingStore = onboardingStore
        currentScreen = onboardingStore.hasCompletedOnboarding ? .login : .landing
    }

    convenience init() {
        self.init(onboardingStore: OnboardingStore.shared)
    }

    var landingItems: [CarouselItem] {
        [
            .welcome(
                appName: L10n.loginHeroTitle,
                tagline: L10n.onboardingWelcomeTagline
            ),
            CarouselItem(
                title: L10n.onboardingTeamTitle,
                imageSource: "https://images.printkk.com/product/football-jersey-wjmqj-718.png",
                subtitle: L10n.onboardingTeamSubtitle,
                backgroundColor: .white
            ),
            CarouselItem(
                title: L10n.onboardingPlanningTitle,
                imageSource: "https://www.radiofrance.fr/pikapi/images/c96aa7d9-e271-49da-99a3-df8d31dece21/1200x680",
                subtitle: L10n.onboardingPlanningSubtitle,
                backgroundColor: .white
            ),
            CarouselItem(
                title: L10n.onboardingStatsTitle,
                imageSource: "https://static.onzemondial.com/8/2022/06/photo_article/784892/309937/1200-L-coupe-du-monde-2022-le-calendrier-complet-de-la-comptition.jpg",
                subtitle: L10n.onboardingStatsSubtitle,
                backgroundColor: .white
            ),
        ]
    }

    func completeOnboarding() {
        onboardingStore.markOnboardingCompleted()
        currentScreen = .login
    }
}
