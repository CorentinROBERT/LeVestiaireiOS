//
//  ProfileViewModel.swift
//  LeVestaire
//
//  Created by Corentin Robert on 16/06/2026.
//

import Combine
import Foundation
import UIKit

@MainActor
final class ProfileViewModel: ObservableObject {
    @Published private(set) var user: User?
    @Published private(set) var sportProfile: SportProfileData?
    @Published private(set) var seasonStats: UserSeasonStats?
    @Published private(set) var availableSeasons: [String] = []
    @Published var selectedSeason = ""
    @Published private(set) var isLoading = false
    @Published private(set) var isLoadingStats = false
    @Published private(set) var isLoggingOut = false
    @Published private(set) var isUploadingPhoto = false
    @Published private(set) var isDeletingAccount = false
    @Published private(set) var isCancellingDeletion = false
    @Published var profileImage: UIImage?
    @Published var showsSettings = false
    @Published var showsEditSportProfile = false
    @Published var showsLogoutConfirmation = false
    @Published var showsDeleteAccountConfirmation = false
    @Published var alertMessage: String?

    private var cancellables = Set<AnyCancellable>()
    private let authService: AuthService
    private let sportProfileService: SportProfileService
    private let statsService: StatsService
    private let accountService: AccountService

    init(
        authService: AuthService,
        sportProfileService: SportProfileService,
        statsService: StatsService,
        accountService: AccountService
    ) {
        self.authService = authService
        self.sportProfileService = sportProfileService
        self.statsService = statsService
        self.accountService = accountService
        self.user = authService.currentUser

        authService.$currentUser
            .receive(on: DispatchQueue.main)
            .sink { [weak self] currentUser in
                self?.user = currentUser
            }
            .store(in: &cancellables)
    }

    convenience init() {
        self.init(
            authService: AuthService.shared,
            sportProfileService: SportProfileService.shared,
            statsService: StatsService.shared,
            accountService: AccountService.shared
        )
    }

    var avatarURL: String? {
        RemoteMediaURL.resolve(user?.avatar)
            ?? RemoteMediaURL.resolve(sportProfile?.profileImageUrl)
    }

    var initials: String {
        user?.initials ?? "?"
    }

    var hasPendingAccountDeletion: Bool {
        user?.accountDeletion?.hasPendingDeletion == true
    }

    var accountDeletionDaysRemaining: Int {
        user?.accountDeletion?.daysRemaining ?? 0
    }

    var canCancelAccountDeletion: Bool {
        user?.accountDeletion?.canCancel ?? false
    }

    func loadProfile() async {
        guard !isLoading else { return }

        isLoading = true
        defer { isLoading = false }

        if let fetchedUser = await authService.fetchCurrentUser() {
            user = fetchedUser
        } else {
            user = authService.currentUser
        }

        let profileResponse = await sportProfileService.fetchProfile()
        if profileResponse.success {
            sportProfile = profileResponse.data
        }

        let seasons = await statsService.fetchAvailableSeasons()
        availableSeasons = seasons

        if selectedSeason.isEmpty, let firstSeason = seasons.last ?? seasons.first {
            selectedSeason = firstSeason
        } else if !selectedSeason.isEmpty, !seasons.contains(selectedSeason), let fallback = seasons.last {
            selectedSeason = fallback
        }

        await loadSeasonStats()
    }

    func reloadAfterSportProfileEdit() {
        showsEditSportProfile = false

        Task {
            let profileResponse = await sportProfileService.fetchProfile()
            if profileResponse.success {
                sportProfile = profileResponse.data
            }
            _ = await authService.fetchCurrentUser()
            user = authService.currentUser
        }
    }

    func onSeasonChanged() {
        Task {
            await loadSeasonStats()
        }
    }

    func handleProfileImageChange(to newImage: UIImage?) {
        guard let newImage else { return }
        guard !isUploadingPhoto else { return }

        Task {
            isUploadingPhoto = true
            defer { isUploadingPhoto = false }

            let response = await sportProfileService.uploadProfilePicture(newImage)

            if response.imageUrl != nil || response.success {
                _ = await authService.fetchCurrentUser()
                user = authService.currentUser
                return
            }

            profileImage = nil
            alertMessage = L10n.apiMessage(response.message) ?? L10n.uploadProfilePhotoFailed
        }
    }

    func requestAccountDeletion() {
        guard !isDeletingAccount else { return }

        Task {
            isDeletingAccount = true
            defer { isDeletingAccount = false }

            let response = await accountService.requestAccountDeletion()

            if response.success {
                _ = await authService.fetchCurrentUser()
                user = authService.currentUser
                alertMessage = L10n.deleteAccountSuccess
                return
            }

            alertMessage = L10n.apiMessage(response.userFacingMessage)
                ?? response.userFacingMessage
                ?? L10n.deleteAccountError
        }
    }

    func cancelAccountDeletion() {
        guard !isCancellingDeletion else { return }

        Task {
            isCancellingDeletion = true
            defer { isCancellingDeletion = false }

            let response = await accountService.cancelAccountDeletion()

            if response.success {
                _ = await authService.fetchCurrentUser()
                user = authService.currentUser
                alertMessage = L10n.accountDeletionCancelled
                return
            }

            alertMessage = L10n.apiMessage(response.userFacingMessage)
                ?? response.userFacingMessage
                ?? L10n.cancelDeletionError
        }
    }

    func logout() {
        guard !isLoggingOut else { return }

        isLoggingOut = true

        Task {
            defer { isLoggingOut = false }
            await authService.logout()
        }
    }

    func strongFootLabel(for rawValue: String?) -> String {
        guard let rawValue,
              let foot = StrongFoot(rawValue: rawValue) else {
            return L10n.none
        }
        return foot.displayName
    }

    func jerseyNumberLabel(for value: Int?) -> String {
        guard let value else { return L10n.none }
        return String(value)
    }

    private func loadSeasonStats() async {
        guard let userId = user?.id, !userId.isEmpty, !selectedSeason.isEmpty else {
            seasonStats = nil
            return
        }

        isLoadingStats = true
        defer { isLoadingStats = false }

        seasonStats = await statsService.fetchUserSeasonStats(
            userId: userId,
            season: selectedSeason
        )
    }
}
