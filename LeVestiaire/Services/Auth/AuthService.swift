//
//  AuthService.swift
//  LeVestaire
//
//  Created by Corentin Robert on 15/06/2026.
//

import Combine
import Foundation

enum SessionGateFailure: Equatable {
    case meFailed
    case biometricFailed
}

@MainActor
final class AuthService: ObservableObject {
    static let shared = AuthService(
        client: APIClient.shared,
        tokenStore: AuthTokenStore.shared,
        pendingCredentialsStore: PendingAuthCredentialsStore.shared,
        sportProfileCompletionStore: SportProfileCompletionStore.shared
    )

    @Published private(set) var currentUser: User?
    @Published private(set) var isAuthenticated = false
    @Published private(set) var isBootstrapComplete = false
    @Published private(set) var requiresPasswordReauthentication = false
    @Published private(set) var requiresSportProfileCompletion = false
    @Published private(set) var authToken: String?
    @Published private(set) var tokenExpiry: Date?

    private let client: APIClient
    private let tokenStore: AuthTokenStore
    private let pendingCredentialsStore: PendingAuthCredentialsStore
    private let sportProfileCompletionStore: SportProfileCompletionStore
    private var tokens: AuthTokens?
    private var ongoingRefresh: Task<Bool, Never>?

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
        client.setAuthInterceptor(self)
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
        guard loadPendingTokens() else {
            isBootstrapComplete = true
            return
        }

        if await completeSessionGate() != nil {
            requiresPasswordReauthentication = true
            await logout()
            isBootstrapComplete = true
            return
        }

        requiresPasswordReauthentication = false
        isBootstrapComplete = true
        await refreshSportProfileRequirement()
    }

    @MainActor
    @discardableResult
    func fetchCurrentUser(retryOnUnauthorized: Bool = true) async -> User? {
        guard let accessToken = authToken, !accessToken.isEmpty else {
            return nil
        }

        do {
            let (data, response) = try await client.request(
                path: APIEndpoints.me,
                method: "GET",
                headers: ["Authorization": "Bearer \(accessToken)"],
                retryOnUnauthorized: retryOnUnauthorized
            )

            guard (200...299).contains(response.statusCode) else {
                return nil
            }

            let user = try APIResponseDecoder.decodeUser(from: data)
            currentUser = user
            return user
        } catch {
            return nil
        }
    }

    @MainActor
    func updateCurrentUser(_ user: User) {
        currentUser = user
    }

    @MainActor
    func login(email: String, password: String) async -> LoginResponse {
        do {
            let body = try JSONEncoder().encode(LoginRequest(email: email, password: password))
            let (data, response) = try await client.request(
                path: APIEndpoints.login,
                method: "POST",
                body: body
            )

            guard HTTPResponseValidator.isSuccess(response) else {
                return LoginResponse(
                    success: false,
                    message: HTTPResponseValidator.localizedErrorMessage(
                        from: data,
                        fallback: L10n.text("loginError")
                    )
                )
            }

            let loginResponse = APIResponseDecoder.decodeLoginResponse(from: data)
            if shouldEstablishSession(from: loginResponse) {
                await establishSession(from: loginResponse)
            }
            return loginResponse
        } catch {
            return LoginResponse(
                success: false,
                message: L10n.loginErrorWithDetail(error.localizedDescription)
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
        language: String? = nil,
        teamInviteCode: String? = nil
    ) async -> LoginResponse {
        do {
            let payload = RegisterRequest(
                email: email,
                password: password,
                firstName: firstName,
                lastName: lastName,
                birthDate: birthDate,
                language: language,
                teamInviteCode: teamInviteCode
            )
            let body = try JSONEncoder().encode(payload)
            let (data, response) = try await client.request(
                path: APIEndpoints.register,
                method: "POST",
                body: body
            )

            guard HTTPResponseValidator.isSuccess(response) else {
                return LoginResponse(
                    success: false,
                    message: HTTPResponseValidator.localizedErrorMessage(
                        from: data,
                        fallback: L10n.text("registerError")
                    )
                )
            }

            let loginResponse = APIResponseDecoder.decodeLoginResponse(from: data)
            if shouldEstablishSession(from: loginResponse) {
                await establishSession(from: loginResponse)
            }
            return loginResponse
        } catch {
            return LoginResponse(
                success: false,
                message: L10n.registerErrorWithDetail(error.localizedDescription)
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
                message: L10n.resendVerificationErrorWithDetail(error.localizedDescription)
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
                    message: L10n.invalidApiResponseNoData
                )
            }

            return try APIResponseDecoder.decode(EmailVerificationResponse.self, from: data)
        } catch {
            return EmailVerificationResponse(
                success: false,
                message: L10n.emailVerificationErrorWithDetail(error.localizedDescription)
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
                    error: L10n.invalidApiResponseNoData
                )
            }

            return try APIResponseDecoder.decode(PasswordResetResponse.self, from: data)
        } catch {
            return PasswordResetResponse(
                success: false,
                error: L10n.passwordResetRequestErrorWithDetail(error.localizedDescription)
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
                    error: L10n.invalidApiResponseNoData
                )
            }

            return try APIResponseDecoder.decode(PasswordResetResponse.self, from: data)
        } catch {
            return PasswordResetResponse(
                success: false,
                error: L10n.passwordResetConfirmErrorWithDetail(error.localizedDescription)
            )
        }
    }

    @MainActor
    func logout() async {
        currentUser = nil
        isAuthenticated = false
        requiresSportProfileCompletion = false
        requiresPasswordReauthentication = true
        authToken = nil
        tokenExpiry = nil
        tokens = nil
        tokenStore.clearTokens()
        pendingCredentialsStore.clear()
        sportProfileCompletionStore.clear()
    }

    @MainActor
    private func clearTransientSession() {
        currentUser = nil
        authToken = nil
        tokens = nil
        isAuthenticated = false
    }

    @MainActor
    private func loadPendingTokens() -> Bool {
        guard let storedTokens = tokenStore.loadTokens() else { return false }

        tokens = storedTokens
        authToken = storedTokens.accessToken
        return true
    }

    @MainActor
    @discardableResult
    private func completeSessionGate() async -> SessionGateFailure? {
        guard let accessToken = authToken, !accessToken.isEmpty,
              let refreshToken = tokens?.refreshToken, !refreshToken.isEmpty else {
            return .meFailed
        }

        guard await fetchCurrentUser(retryOnUnauthorized: true) != nil else {
            return .meFailed
        }

        if BiometricAuthStore.shared.isEnabled {
            let verified = await BiometricAuthStore.shared.verifyForAccess()
            guard verified else {
                return .biometricFailed
            }
        }

        tokenStore.saveTokens(accessToken: accessToken, refreshToken: refreshToken)
        isAuthenticated = true
        requiresPasswordReauthentication = false
        return nil
    }

    @MainActor
    private func establishSession(from loginResponse: LoginResponse) async {
        guard loginResponse.success,
              loginResponse.hasValidData,
              let accessToken = loginResponse.accessToken,
              let refreshToken = loginResponse.refreshToken else {
            return
        }

        authToken = accessToken
        tokens = AuthTokens(accessToken: accessToken, refreshToken: refreshToken)

        guard await completeSessionGate() == nil else {
            clearTransientSession()
            return
        }

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
    private func applyRefreshedTokens(accessToken: String, refreshToken: String) {
        tokens = AuthTokens(accessToken: accessToken, refreshToken: refreshToken)
        authToken = accessToken
        tokenStore.saveTokens(accessToken: accessToken, refreshToken: refreshToken)
    }

    @MainActor
    @discardableResult
    func refreshAccessTokenIfNeeded() async -> Bool {
        if let ongoingRefresh {
            return await ongoingRefresh.value
        }

        let task = Task { @MainActor [weak self] in
            await self?.performRefresh() ?? false
        }
        ongoingRefresh = task
        defer { ongoingRefresh = nil }
        return await task.value
    }

    @MainActor
    private func performRefresh() async -> Bool {
        guard let refreshToken = tokens?.refreshToken, !refreshToken.isEmpty else {
            return false
        }

        do {
            let body = try JSONEncoder().encode(["refreshToken": refreshToken])
            let (data, response) = try await client.request(
                path: APIEndpoints.refresh,
                method: "POST",
                body: body,
                retryOnUnauthorized: false
            )

            guard (200...299).contains(response.statusCode) else {
                return false
            }

            let loginResponse = APIResponseDecoder.decodeLoginResponse(from: data)
            guard loginResponse.success, loginResponse.hasValidTokens,
                  let accessToken = loginResponse.accessToken,
                  !accessToken.isEmpty else {
                return false
            }

            let refreshToken = loginResponse.refreshToken ?? tokens?.refreshToken
            guard let refreshToken, !refreshToken.isEmpty else {
                return false
            }

            applyRefreshedTokens(accessToken: accessToken, refreshToken: refreshToken)

            if let user = loginResponse.user {
                currentUser = user
            }

            return true
        } catch {
            return false
        }
    }

    @MainActor
    func configureUnauthenticatedForUITesting() {
        isBootstrapComplete = true
        isAuthenticated = false
        requiresPasswordReauthentication = false
        requiresSportProfileCompletion = false
        currentUser = nil
        authToken = nil
        tokens = nil
    }

    @MainActor
    func configureAuthenticatedForUITesting(requiresSportProfile: Bool) {
        isBootstrapComplete = true
        isAuthenticated = true
        requiresPasswordReauthentication = false
        currentUser = User(
            id: "ui-test-user",
            email: "uitest@levestaire.test",
            firstName: "Test",
            lastName: "UI",
            isActive: true,
            emailVerified: true
        )
        authToken = "ui-test-access-token"
        tokens = AuthTokens(
            accessToken: "ui-test-access-token",
            refreshToken: "ui-test-refresh-token"
        )
        tokenStore.saveTokens(
            accessToken: "ui-test-access-token",
            refreshToken: "ui-test-refresh-token"
        )

        if requiresSportProfile {
            markSportProfileRequired()
        } else {
            markSportProfileCompleted()
        }
    }
}

extension AuthService: APIAuthIntercepting {
    func refreshAccessToken() async -> String? {
        let refreshed = await refreshAccessTokenIfNeeded()
        guard refreshed, let accessToken = authToken, !accessToken.isEmpty else {
            return nil
        }
        return accessToken
    }

    func forceLogout() async {
        guard !UITestLaunchArgument.isEnabled else { return }
        await logout()
    }
}
