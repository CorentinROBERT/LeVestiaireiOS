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
    @Published var birthDate: Date?
    @Published var selectedLanguage: AppLanguage = .french
    @Published var hasAcceptedLegalTerms = false
    @Published var validationMessage: String?
    @Published var showEmailVerification = false
    @Published var isLoading = false

    var onRegistered: ((String) -> Void)?

    private let authService: any AuthServicing
    private let pendingCredentialsStore: any PendingAuthCredentialsStoring
    private let teamInviteCoordinator: any TeamInviteCoordinating

    var pendingInviteTeamName: String? {
        teamInviteCoordinator.pendingInviteTeamName
    }

    var trimmedEmail: String {
        email.trimmed
    }

    init(
        authService: any AuthServicing,
        pendingCredentialsStore: any PendingAuthCredentialsStoring,
        teamInviteCoordinator: any TeamInviteCoordinating,
        onRegistered: ((String) -> Void)? = nil
    ) {
        self.authService = authService
        self.pendingCredentialsStore = pendingCredentialsStore
        self.teamInviteCoordinator = teamInviteCoordinator
        self.onRegistered = onRegistered
    }

    convenience init(onRegistered: ((String) -> Void)? = nil) {
        self.init(
            authService: AuthService.shared,
            pendingCredentialsStore: PendingAuthCredentialsStore.shared,
            teamInviteCoordinator: TeamInviteCoordinator.shared,
            onRegistered: onRegistered
        )
        selectedLanguage = LocalizationManager.shared.language
    }

    convenience init() {
        self.init(onRegistered: nil)
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

        if let birthDate, birthDate > Date() {
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
                onRegistered?(trimmedEmail)
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
