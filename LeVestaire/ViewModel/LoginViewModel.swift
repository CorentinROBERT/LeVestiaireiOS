//
//  LoginViewModel.swift
//  LeVestaire
//
//  Created by Corentin Robert on 12/06/2026.
//

import Combine
import Foundation

final class LoginViewModel: ObservableObject {
    private static let developerAccessPassword = "asdescopains"
    private static let developerTapThreshold = 5
    private static let developerTapResetInterval: TimeInterval = 2

    @Published var email = ""
    @Published var password = ""
    @Published var isPasswordVisible = false
    @Published var showDeveloperPasswordDialog = false
    @Published var showDeveloperPasswordError = false
    @Published var showDeveloperPage = false
    @Published var developerPasswordInput = ""

    private var developerTapCount = 0
    private var lastDeveloperTapDate: Date?

    func registerDeveloperTap() {
        let now = Date()

        if let lastTap = lastDeveloperTapDate,
           now.timeIntervalSince(lastTap) > Self.developerTapResetInterval {
            developerTapCount = 0
        }

        lastDeveloperTapDate = now
        developerTapCount += 1

        guard developerTapCount >= Self.developerTapThreshold else { return }

        developerTapCount = 0
        developerPasswordInput = ""
        showDeveloperPasswordDialog = true
    }

    func validateDeveloperPassword() {
        guard developerPasswordInput == Self.developerAccessPassword else {
            showDeveloperPasswordDialog = false
            developerPasswordInput = ""
            showDeveloperPasswordError = true
            return
        }

        showDeveloperPasswordDialog = false
        developerPasswordInput = ""
        showDeveloperPage = true
    }

    func cancelDeveloperPassword() {
        developerPasswordInput = ""
        showDeveloperPasswordDialog = false
    }

    func login() {
        // TODO: brancher l'authentification
    }
}
