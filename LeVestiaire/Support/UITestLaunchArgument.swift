//
//  UITestLaunchArgument.swift
//  LeVestaire
//

import Foundation

enum UITestScenario: String {
    case landing
    case login
    case authenticated
    case sportProfile
}

enum UITestLaunchArgument {
    static let enabled = "-UITesting"
    static let scenarioFlag = "-UITestScenario"
    static let enabledEnvironmentKey = "UITESTING"
    static let scenarioEnvironmentKey = "UITEST_SCENARIO"
    static let openResetPassword = "-UITestOpenResetPassword"
    static let populatedNotifications = "-UITestPopulatedNotifications"

    static var usesPopulatedNotifications: Bool {
        ProcessInfo.processInfo.arguments.contains(populatedNotifications)
            || ProcessInfo.processInfo.environment["UITEST_POPULATED_NOTIFICATIONS"] == "1"
    }

    static var isEnabled: Bool {
        ProcessInfo.processInfo.arguments.contains(enabled)
            || ProcessInfo.processInfo.environment[enabledEnvironmentKey] == "1"
    }

    static var scenario: UITestScenario {
        if let environmentValue = ProcessInfo.processInfo.environment[scenarioEnvironmentKey],
           let scenario = UITestScenario(rawValue: environmentValue) {
            return scenario
        }

        guard let index = ProcessInfo.processInfo.arguments.firstIndex(of: scenarioFlag),
              ProcessInfo.processInfo.arguments.indices.contains(index + 1),
              let value = UITestScenario(
                rawValue: ProcessInfo.processInfo.arguments[index + 1]
              ) else {
            return .login
        }
        return value
    }

    static var shouldOpenResetPassword: Bool {
        ProcessInfo.processInfo.arguments.contains(openResetPassword)
            || ProcessInfo.processInfo.environment["UITEST_OPEN_RESET_PASSWORD"] == "1"
    }

    static var usesNetworkStub: Bool {
        switch scenario {
        case .authenticated, .sportProfile, .login:
            return true
        case .landing:
            return false
        }
    }
}
