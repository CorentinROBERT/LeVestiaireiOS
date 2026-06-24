//
//  RegisterViewModel.swift
//  LeVestaire
//
//  Created by Corentin Robert on 14/06/2026.
//

import Combine
import Foundation

@MainActor
final class RegisterViewModel: ObservableObject {
    @Published var lastName = ""
    @Published var firstName = ""
    @Published var email = ""
    @Published var password = ""
    @Published var confirmPassword = ""
    @Published var isPasswordVisible = false
    @Published var isConfirmPasswordVisible = false
    @Published var birthDate = Calendar.current.date(byAdding: .year, value: -18, to: Date()) ?? Date()
    @Published var selectedLanguage: AppLanguage = .french
    @Published var hasAcceptedLegalTerms = false
    @Published var validationMessage: String?
    @Published var showEmailVerification = false
    @Published var isLoading = false

    private let authService: AuthService
    private let pendingCredentialsStore: PendingAuthCredentialsStore
    private let teamInviteCoordinator: TeamInviteCoordinator

    var pendingInviteTeamName: String? {
        teamInviteCoordinator.pendingInviteTeamName
    }

    var trimmedEmail: String {
        email.trimmed
    }

    init(
        authService: AuthService,
        pendingCredentialsStore: PendingAuthCredentialsStore,
        teamInviteCoordinator: TeamInviteCoordinator
    ) {
        self.authService = authService
        self.pendingCredentialsStore = pendingCredentialsStore
        self.teamInviteCoordinator = teamInviteCoordinator
    }

    convenience init() {
        self.init(
            authService: AuthService.shared,
            pendingCredentialsStore: PendingAuthCredentialsStore.shared,
            teamInviteCoordinator: .shared
        )
        selectedLanguage = LocalizationManager.shared.language
    }

    var canSubmit: Bool {
        !lastName.trimmed.isEmpty
            && !firstName.trimmed.isEmpty
            && !trimmedEmail.isEmpty
            && !password.isEmpty
            && !confirmPassword.isEmpty
            && hasAcceptedLegalTerms
            && !isLoading
    }

    func createAccount() {
        validationMessage = nil

        guard canSubmit else {
            validationMessage = L10n.registerFormIncomplete
            return
        }

        let trimmedEmail = trimmedEmail

        guard trimmedEmail.isValidEmail else {
            validationMessage = L10n.emailInvalid
            return
        }

        guard password == confirmPassword else {
            validationMessage = L10n.passwordsDoNotMatch
            return
        }

        guard password.count >= 8 else {
            validationMessage = L10n.passwordMin8Characters
            return
        }

        guard birthDate <= Date() else {
            validationMessage = L10n.invalidBirthDate
            return
        }

        isLoading = true

        Task {
            defer { isLoading = false }

            let response = await authService.register(
                email: trimmedEmail,
                password: password,
                firstName: firstName.trimmed,
                lastName: lastName.trimmed,
                birthDate: birthDate,
                language: selectedLanguage.rawValue,
                teamInviteCode: teamInviteCoordinator.pendingCode
            )

            if response.success {
                LocalizationManager.shared.setLanguage(selectedLanguage)
                pendingCredentialsStore.save(email: trimmedEmail, password: password)
                showEmailVerification = true
                return
            }

            validationMessage = L10n.apiErrorMessage(
                message: response.message,
                error: response.error,
                fallback: L10n.registerFailed
            )
        }
    }
}
