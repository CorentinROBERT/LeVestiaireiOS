//
//  EmailVerificationViewModel.swift
//  LeVestaire
//
//  Created by Corentin Robert on 14/06/2026.
//

import Combine
import Foundation

final class EmailVerificationViewModel: ObservableObject {
    private static let resendCooldownDuration = 20

    let email: String

    @Published var isCheckingVerification = false
    @Published var isResending = false
    @Published var feedbackMessage: String?
    @Published var resendCooldownRemaining = 0
    @Published var showSportProfile = false

    private var resendCooldownTask: Task<Void, Never>?

    var canResendEmail: Bool {
        resendCooldownRemaining == 0 && !isResending
    }

    init(email: String) {
        self.email = email
    }

    deinit {
        resendCooldownTask?.cancel()
    }

    func confirmVerification() {
        guard !isCheckingVerification else { return }

        isCheckingVerification = true
        feedbackMessage = nil

        Task { @MainActor in
            defer { isCheckingVerification = false }

            let isVerified = await checkEmailVerificationStatus()

            if isVerified {
                showSportProfile = true
            } else {
                feedbackMessage = "Votre email n'est pas encore vérifié. Consultez votre boîte mail et réessayez."
            }
        }
    }

    private func checkEmailVerificationStatus() async -> Bool {
        // TODO: vérifier auprès de l'API que le compte est activé
        return true
    }

    func resendEmail() {
        guard canResendEmail else { return }

        isResending = true
        feedbackMessage = nil

        Task { @MainActor in
            defer { isResending = false }

            // TODO: appeler l'API de renvoi d'email de vérification
            feedbackMessage = "Un nouvel email de vérification a été envoyé."
            startResendCooldown()
        }
    }

    @MainActor
    private func startResendCooldown() {
        resendCooldownTask?.cancel()
        resendCooldownRemaining = Self.resendCooldownDuration

        resendCooldownTask = Task {
            while resendCooldownRemaining > 0 {
                try? await Task.sleep(nanoseconds: 1_000_000_000)
                guard !Task.isCancelled else { return }
                resendCooldownRemaining -= 1
            }
        }
    }
}
