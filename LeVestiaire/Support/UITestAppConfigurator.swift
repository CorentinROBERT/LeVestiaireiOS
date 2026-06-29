//
//  UITestAppConfigurator.swift
//  LeVestaire
//

import Foundation

@MainActor
enum UITestAppConfigurator {
    private static var configuredScenario: UITestScenario?

    static func configureIfNeeded(
        authService: AuthService,
        onboardingStore: OnboardingStore = .shared,
        tokenStore: AuthTokenStore = .shared,
        sportProfileStore: SportProfileCompletionStore = .shared
    ) {
        guard UITestLaunchArgument.isEnabled else { return }

        let scenario = UITestLaunchArgument.scenario
        guard configuredScenario != scenario else { return }
        configuredScenario = scenario

        tokenStore.clearTokens()
        sportProfileStore.clear()

        switch scenario {
        case .landing:
            UserDefaults.standard.removeObject(forKey: "hasCompletedOnboarding")
            authService.configureUnauthenticatedForUITesting()
        case .login:
            onboardingStore.markOnboardingCompleted()
            authService.configureUnauthenticatedForUITesting()
        case .authenticated:
            onboardingStore.markOnboardingCompleted()
            authService.configureAuthenticatedForUITesting(requiresSportProfile: false)
        case .sportProfile:
            onboardingStore.markOnboardingCompleted()
            authService.configureAuthenticatedForUITesting(requiresSportProfile: true)
        }

        APIClient.shared.installUITestNetworkingIfNeeded()
    }
}
