//
//  DeveloperAccessViewModel.swift
//  LeVestaire
//

import Combine
import Foundation

@MainActor
final class DeveloperAccessViewModel: ObservableObject {
    private static let accessPassword = "asdescopains"
    private static let tapThreshold = 5
    private static let tapResetInterval: TimeInterval = 2

    @Published var showPasswordDialog = false
    @Published var showPasswordError = false
    @Published var showDeveloperPage = false
    @Published var passwordInput = ""

    private var tapCount = 0
    private var lastTapDate: Date?

    func registerTap() {
        let now = Date()

        if let lastTap = lastTapDate,
           now.timeIntervalSince(lastTap) > Self.tapResetInterval {
            tapCount = 0
        }

        lastTapDate = now
        tapCount += 1

        guard tapCount >= Self.tapThreshold else { return }

        tapCount = 0
        passwordInput = ""
        showPasswordDialog = true
    }

    func validatePassword() {
        guard passwordInput == Self.accessPassword else {
            showPasswordDialog = false
            passwordInput = ""
            showPasswordError = true
            return
        }

        showPasswordDialog = false
        passwordInput = ""
        showDeveloperPage = true
    }

    func cancelPasswordEntry() {
        passwordInput = ""
        showPasswordDialog = false
    }
}
