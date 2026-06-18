//
//  BiometricAuthStore.swift
//  LeVestaire
//
//  Created by Corentin Robert on 16/06/2026.
//

import Combine
import Foundation
import LocalAuthentication

@MainActor
final class BiometricAuthStore: ObservableObject {
    static let shared = BiometricAuthStore()

    private static let storageKey = "biometric_auth_enabled"

    @Published private(set) var isEnabled = false
    @Published private(set) var isVerifying = false
    @Published var lastErrorMessage: String?

    private init(userDefaults: UserDefaults = .standard) {
        let storedValue = userDefaults.bool(forKey: Self.storageKey)
        let isAvailable = Self.checkBiometricAvailability().isAvailable
        isEnabled = storedValue && isAvailable
    }

    var isAvailable: Bool {
        Self.checkBiometricAvailability().isAvailable
    }

    var biometryLabel: String {
        let context = LAContext()
        _ = context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: nil)

        switch context.biometryType {
        case .faceID:
            return "Face ID"
        case .touchID:
            return "Touch ID"
        case .opticID:
            return "Optic ID"
        default:
            return L10n.biometricLogin
        }
    }

    func disable() {
        persistEnabled(false)
        lastErrorMessage = nil
    }

    @discardableResult
    func verifyForAccess() async -> Bool {
        guard isEnabled else { return true }

        let availability = Self.checkBiometricAvailability()
        guard availability.isAvailable else {
            lastErrorMessage = availability.errorMessage ?? L10n.biometricUnavailable
            return false
        }

        lastErrorMessage = nil
        isVerifying = true
        defer { isVerifying = false }

        let context = LAContext()
        context.localizedCancelTitle = L10n.cancel

        do {
            try await evaluateBiometrics(
                context: context,
                reason: L10n.biometricUnlockReason
            )
            return true
        } catch let error as LAError {
            lastErrorMessage = localizedMessage(for: error)
            return false
        } catch {
            lastErrorMessage = L10n.biometricAuthenticationFailed
            return false
        }
    }

    @discardableResult
    func enableWithVerification(refreshToken: String?) async -> Bool {
        lastErrorMessage = nil

        let availability = Self.checkBiometricAvailability()
        guard availability.isAvailable else {
            persistEnabled(false)
            lastErrorMessage = availability.errorMessage ?? L10n.biometricUnavailable
            return false
        }

        guard let refreshToken,
              !refreshToken.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            lastErrorMessage = L10n.sessionRequired
            return false
        }

        isVerifying = true
        defer { isVerifying = false }

        let context = LAContext()
        context.localizedCancelTitle = L10n.cancel

        do {
            try await evaluateBiometrics(
                context: context,
                reason: L10n.biometricEnableReason
            )
            persistEnabled(true)
            return true
        } catch let error as LAError {
            persistEnabled(false)
            lastErrorMessage = localizedMessage(for: error)
            return false
        } catch {
            persistEnabled(false)
            lastErrorMessage = L10n.biometricAuthenticationFailed
            return false
        }
    }

    private func persistEnabled(_ value: Bool) {
        isEnabled = value
        UserDefaults.standard.set(value, forKey: Self.storageKey)
    }

    private func evaluateBiometrics(context: LAContext, reason: String) async throws {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            context.evaluatePolicy(
                .deviceOwnerAuthenticationWithBiometrics,
                localizedReason: reason
            ) { success, error in
                if let error {
                    continuation.resume(throwing: error)
                } else if success {
                    continuation.resume()
                } else {
                    continuation.resume(throwing: LAError(.authenticationFailed))
                }
            }
        }
    }

    private func localizedMessage(for error: LAError) -> String {
        switch error.code {
        case .biometryNotAvailable:
            return L10n.biometricUnavailable
        case .biometryNotEnrolled:
            return L10n.biometricNotEnrolled
        case .biometryLockout:
            return L10n.biometricLockout
        case .userCancel, .appCancel, .systemCancel:
            return L10n.biometricCancelled
        case .authenticationFailed:
            return L10n.biometricAuthenticationFailed
        default:
            return L10n.biometricAuthenticationFailed
        }
    }

    private static func checkBiometricAvailability() -> (isAvailable: Bool, errorMessage: String?) {
        let context = LAContext()
        var error: NSError?

        guard context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) else {
            if let laError = error as? LAError {
                switch laError.code {
                case .biometryNotEnrolled:
                    return (false, L10n.biometricNotEnrolled)
                case .biometryLockout:
                    return (false, L10n.biometricLockout)
                default:
                    return (false, L10n.biometricUnavailable)
                }
            }
            return (false, L10n.biometricUnavailable)
        }

        return (true, nil)
    }
}
