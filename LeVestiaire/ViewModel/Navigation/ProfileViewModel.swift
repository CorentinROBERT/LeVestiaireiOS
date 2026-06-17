//
//  ProfileViewModel.swift
//  LeVestaire
//
//  Created by Corentin Robert on 16/06/2026.
//

import Combine
import Foundation

@MainActor
final class ProfileViewModel: ObservableObject {
    @Published private(set) var isLoggingOut = false

    private let authService: AuthService

    init(authService: AuthService) {
        self.authService = authService
    }

    convenience init() {
        self.init(authService: AuthService.shared)
    }

    func logout() {
        guard !isLoggingOut else { return }

        isLoggingOut = true

        Task {
            defer { isLoggingOut = false }
            await authService.logout()
        }
    }
}
