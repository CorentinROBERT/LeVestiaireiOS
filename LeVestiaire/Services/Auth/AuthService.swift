//
//  AuthService.swift
//  LeVestaire
//
//  Created by Corentin Robert on 15/06/2026.
//

import Combine
import Foundation

final class AuthService: ObservableObject {
    static let shared = AuthService(
        client: APIClient.shared,
        tokenStore: AuthTokenStore.shared,
        pendingCredentialsStore: PendingAuthCredentialsStore.shared,
        sportProfileCompletionStore: SportProfileCompletionStore.shared
    )

    @Published private(set) var currentUser: User?
    @Published private(set) var isAuthenticated = false
    @Published private(set) var requiresSportProfileCompletion = false
    @Published private(set) var authToken: String?
    @Published private(set) var tokenExpiry: Date?

    private let client: APIClient
    private let tokenStore: AuthTokenStore
    private let pendingCredentialsStore: PendingAuthCredentialsStore
    private let sportProfileCompletionStore: SportProfileCompletionStore
    private var tokens: AuthTokens?

    init(
        client: APIClient,
        tokenStore: AuthTokenStore,
        pendingCredentialsStore: PendingAuthCredentialsStore,
        sportProfileCompletionStore: SportProfileCompletionStore
    ) {
        self.client = client
        self.tokenStore = tokenStore
        self.pendingCredentialsStore = pendingCredentialsStore
        self.sportProfileCompletionStore = sportProfileCompletionStore
    }

    var refreshToken: String? {
        tokens?.refreshToken
    }

    @MainActor
    func markSportProfileRequired() {
        sportProfileCompletionStore.markRequired()
        requiresSportProfileCompletion = true
    }

    @MainActor
    func markSportProfileCompleted() {
        sportProfileCompletionStore.markCompleted()
        requiresSportProfileCompletion = false
    }

    @MainActor
    func initialize() async {
        loadStoredTokens()
        guard isAuthenticated else { return }

        let isSessionValid = await validateStoredSession()
        if !isSessionValid {
            await logout()
            return
        }

        await refreshSportProfileRequirement()
    }

    @MainActor
    func login(email: String, password: String) async -> LoginResponse {
        do {
            let body = try JSONEncoder().encode(LoginRequest(email: email, password: password))
            let (data, _) = try await client.request(
                path: APIEndpoints.login,
                method: "POST",
                body: body
            )

            let loginResponse = APIResponseDecoder.decodeLoginResponse(from: data)
            if shouldEstablishSession(from: loginResponse) {
                await establishSession(from: loginResponse)
            }
            return loginResponse
        } catch {
            return LoginResponse(
                success: false,
                message: "Erreur lors de la connexion: \(error.localizedDescription)"
            )
        }
    }

    @MainActor
    func register(
        email: String,
        password: String,
        firstName: String,
        lastName: String,
        birthDate: Date? = nil,
        language: String? = nil
    ) async -> LoginResponse {
        do {
            let payload = RegisterRequest(
                email: email,
                password: password,
                firstName: firstName,
                lastName: lastName,
                birthDate: birthDate,
                language: language
            )
            let body = try JSONEncoder().encode(payload)
            let (data, _) = try await client.request(
                path: APIEndpoints.register,
                method: "POST",
                body: body
            )

            let loginResponse = APIResponseDecoder.decodeLoginResponse(from: data)
            if shouldEstablishSession(from: loginResponse) {
                await establishSession(from: loginResponse)
            }
            return loginResponse
        } catch {
            return LoginResponse(
                success: false,
                message: "Erreur lors de l'inscription: \(error.localizedDescription)"
            )
        }
    }

    func resendVerificationEmail(email: String) async -> LoginResponse {
        do {
            let body = try JSONEncoder().encode(["email": email])
            let (data, _) = try await client.request(
                path: APIEndpoints.resendVerification,
                method: "POST",
                body: body
            )

            return APIResponseDecoder.decodeLoginResponse(from: data)
        } catch {
            return LoginResponse(
                success: false,
                message: "Erreur lors du renvoi de l'email de vérification: \(error.localizedDescription)"
            )
        }
    }

    func checkEmailVerification(email: String) async -> EmailVerificationResponse {
        do {
            let body = try JSONEncoder().encode(["email": email])
            let (data, _) = try await client.request(
                path: APIEndpoints.checkVerification,
                method: "POST",
                body: body
            )

            guard !data.isEmpty else {
                return EmailVerificationResponse(
                    success: false,
                    message: "Réponse API invalide: aucune donnée reçue."
                )
            }

            return try APIResponseDecoder.decode(EmailVerificationResponse.self, from: data)
        } catch {
            return EmailVerificationResponse(
                success: false,
                message: "Erreur lors de la vérification: \(error.localizedDescription)"
            )
        }
    }

    func requestPasswordReset(email: String) async -> PasswordResetResponse {
        do {
            let body = try JSONEncoder().encode(["email": email])
            let (data, _) = try await client.request(
                path: APIEndpoints.requestPasswordReset,
                method: "POST",
                body: body
            )

            guard !data.isEmpty else {
                return PasswordResetResponse(
                    success: false,
                    error: "Réponse API invalide: aucune donnée reçue."
                )
            }

            return try APIResponseDecoder.decode(PasswordResetResponse.self, from: data)
        } catch {
            return PasswordResetResponse(
                success: false,
                error: "Erreur lors de la demande de réinitialisation: \(error.localizedDescription)"
            )
        }
    }

    func confirmPasswordReset(token: String, newPassword: String) async -> PasswordResetResponse {
        do {
            let body = try JSONEncoder().encode([
                "token": token,
                "newPassword": newPassword,
            ])
            let (data, _) = try await client.request(
                path: APIEndpoints.confirmPasswordReset,
                method: "POST",
                body: body
            )

            guard !data.isEmpty else {
                return PasswordResetResponse(
                    success: false,
                    error: "Réponse API invalide: aucune donnée reçue."
                )
            }

            return try APIResponseDecoder.decode(PasswordResetResponse.self, from: data)
        } catch {
            return PasswordResetResponse(
                success: false,
                error: "Erreur lors de la confirmation de réinitialisation: \(error.localizedDescription)"
            )
        }
    }

    @MainActor
    func logout() async {
        currentUser = nil
        isAuthenticated = false
        requiresSportProfileCompletion = false
        authToken = nil
        tokenExpiry = nil
        tokens = nil
        tokenStore.clearTokens()
        pendingCredentialsStore.clear()
        sportProfileCompletionStore.clear()
    }

    @MainActor
    private func loadStoredTokens() {
        guard let storedTokens = tokenStore.loadTokens() else { return }

        tokens = storedTokens
        authToken = storedTokens.accessToken
        isAuthenticated = true
    }

    @MainActor
    private func establishSession(from loginResponse: LoginResponse) async {
        persistSessionIfNeeded(from: loginResponse)
        guard isAuthenticated else { return }
        await refreshSportProfileRequirement()
    }

    @MainActor
    private func refreshSportProfileRequirement() async {
        guard isAuthenticated, let accessToken = authToken, !accessToken.isEmpty else {
            requiresSportProfileCompletion = false
            return
        }

        do {
            let (data, httpResponse) = try await client.request(
                path: APIEndpoints.sportProfile,
                method: "GET",
                headers: ["Authorization": "Bearer \(accessToken)"]
            )

            if httpResponse.statusCode == 404 {
                markSportProfileRequired()
                return
            }

            guard (200...299).contains(httpResponse.statusCode) else {
                return
            }

            let profileResponse = APIResponseDecoder.decodeSportProfileResponse(from: data)
            if profileResponse.hasValidData, profileResponse.data?.isCompleted == true {
                markSportProfileCompleted()
            } else {
                markSportProfileRequired()
            }
        } catch {
            return
        }
    }

    @MainActor
    private func shouldEstablishSession(from response: LoginResponse) -> Bool {
        guard response.success, response.hasValidData else { return false }

        if response.requiresVerification == true { return false }
        if response.isEmailVerified == false { return false }
        if response.emailVerified == false { return false }
        if let user = response.user, !user.emailVerified { return false }

        return true
    }

    @MainActor
    private func persistSessionIfNeeded(from loginResponse: LoginResponse) {
        guard loginResponse.success,
              loginResponse.hasValidData,
              let accessToken = loginResponse.accessToken,
              let refreshToken = loginResponse.refreshToken else {
            return
        }

        tokenStore.saveTokens(accessToken: accessToken, refreshToken: refreshToken)
        tokens = AuthTokens(accessToken: accessToken, refreshToken: refreshToken)
        authToken = accessToken
        isAuthenticated = true
        currentUser = loginResponse.user
    }

    private func validateStoredSession() async -> Bool {
        guard let accessToken = authToken, !accessToken.isEmpty else {
            return false
        }

        do {
            let (_, response) = try await client.request(
                path: APIEndpoints.me,
                method: "GET",
                headers: ["Authorization": "Bearer \(accessToken)"]
            )
            return (200...299).contains(response.statusCode)
        } catch {
            return false
        }
    }
}
