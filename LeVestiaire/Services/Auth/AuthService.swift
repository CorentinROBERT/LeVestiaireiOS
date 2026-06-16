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
        tokenStore: AuthTokenStore.shared
    )

    @Published private(set) var currentUser: User?
    @Published private(set) var isAuthenticated = false
    @Published private(set) var authToken: String?
    @Published private(set) var tokenExpiry: Date?

    private let client: APIClient
    private let tokenStore: AuthTokenStore
    private var tokens: AuthTokens?

    init(client: APIClient, tokenStore: AuthTokenStore) {
        self.client = client
        self.tokenStore = tokenStore
    }

    var refreshToken: String? {
        tokens?.refreshToken
    }

    @MainActor
    func initialize() async {
        loadStoredTokens()
        guard isAuthenticated else { return }

        let isSessionValid = await validateStoredSession()
        if !isSessionValid {
            await logout()
        }
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
            persistSessionIfNeeded(from: loginResponse)
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
            persistSessionIfNeeded(from: loginResponse)
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
        authToken = nil
        tokenExpiry = nil
        tokens = nil
        tokenStore.clearTokens()
    }

    @MainActor
    private func loadStoredTokens() {
        guard let storedTokens = tokenStore.loadTokens() else { return }

        tokens = storedTokens
        authToken = storedTokens.accessToken
        isAuthenticated = true
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
