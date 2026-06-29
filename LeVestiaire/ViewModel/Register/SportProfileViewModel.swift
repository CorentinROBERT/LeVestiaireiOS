//
//  SportProfileViewModel.swift
//  LeVestaire
//
//  Created by Corentin Robert on 14/06/2026.
//

import Combine
import Foundation
import UIKit

@MainActor
final class SportProfileViewModel: ObservableObject {
    @Published var profileImage: UIImage?
    @Published var strongFoot: StrongFoot = .right
    @Published var jerseyNumberText = ""
    @Published var selectedLeague: FootballLeague = .ligue1
    @Published var selectedTeam = ""
    @Published var availableTeams: [String] = []
    @Published var selectedPositions: Set<PlayerPosition> = []
    @Published var experienceLevel: ExperienceLevel = .beginner
    @Published var selectedWeekdays: Set<Weekday> = []
    @Published var validationMessage: String?
    @Published var isLoading = false
    @Published private(set) var isUploadingPhoto = false
    @Published private(set) var uploadedProfileImageUrl: String?
    @Published private(set) var isLoadingExistingProfile = false

    let mode: SportProfileMode
    var onProfileSaved: (() -> Void)?

    private let sportProfileService: any SportProfileServicing
    private let referenceDataService: any ReferenceDataServicing
    private let authService: any AuthServicing

    var isEditMode: Bool {
        mode == .edit
    }

    var submitButtonTitle: String {
        if isLoading {
            return L10n.saving
        }
        return isEditMode ? L10n.save : L10n.finalizeMyProfile
    }

    var canSubmit: Bool {
        !selectedTeam.isEmpty
            && !selectedPositions.isEmpty
            && !selectedWeekdays.isEmpty
            && jerseyNumberValue != nil
            && !isLoading
            && !isUploadingPhoto
    }

    var jerseyNumberValue: Int? {
        guard let value = Int(jerseyNumberText.trimmed),
              (0...999).contains(value) else {
            return nil
        }
        return value
    }

    init(
        mode: SportProfileMode = .onboarding,
        onProfileSaved: (() -> Void)? = nil,
        sportProfileService: any SportProfileServicing,
        referenceDataService: any ReferenceDataServicing,
        authService: any AuthServicing
    ) {
        self.mode = mode
        self.onProfileSaved = onProfileSaved
        self.sportProfileService = sportProfileService
        self.referenceDataService = referenceDataService
        self.authService = authService

        reloadTeamsForSelectedLeague()
    }

    convenience init(
        mode: SportProfileMode = .onboarding,
        onProfileSaved: (() -> Void)? = nil
    ) {
        self.init(
            mode: mode,
            onProfileSaved: onProfileSaved,
            sportProfileService: SportProfileService.shared,
            referenceDataService: ReferenceDataService.shared,
            authService: AuthService.shared
        )
    }

    func loadExistingProfileIfNeeded() async {
        guard isEditMode, !isLoadingExistingProfile else { return }

        isLoadingExistingProfile = true
        defer { isLoadingExistingProfile = false }

        let response = await sportProfileService.fetchProfile()
        guard response.success, let profile = response.data else { return }

        applyExistingProfile(profile)
    }

    func onLeagueChanged() {
        reloadTeamsForSelectedLeague()
    }

    func handleProfileImageChange(to newImage: UIImage?) {
        guard let newImage else {
            uploadedProfileImageUrl = nil
            return
        }

        guard !isUploadingPhoto else { return }

        Task {
            await uploadProfileImage(newImage)
        }
    }

    func updateJerseyNumber(_ input: String) {
        let filtered = input.filter(\.isNumber)
        if filtered.count <= 3 {
            jerseyNumberText = filtered
        } else if let value = Int(filtered), (0...999).contains(value) {
            jerseyNumberText = String(value)
        } else {
            jerseyNumberText = String(filtered.prefix(3))
        }
    }

    func finalizeProfile() {
        validationMessage = nil

        guard canSubmit else {
            validationMessage = L10n.completeRequiredSportFields
            return
        }

        isLoading = true

        Task {
            defer { isLoading = false }

            let request = buildRequest(profileImageUrl: uploadedProfileImageUrl)
            let response = await sportProfileService.saveProfile(request)

            guard response.success, response.hasValidData else {
                validationMessage = L10n.apiMessage(response.userFacingMessage)
                    ?? response.userFacingMessage
                    ?? L10n.saveSportProfileFailed
                return
            }

            if isEditMode {
                onProfileSaved?()
            } else {
                authService.markSportProfileCompleted()
            }
        }
    }

    private func uploadProfileImage(_ image: UIImage) async {
        isUploadingPhoto = true
        defer { isUploadingPhoto = false }

        let response = await sportProfileService.uploadProfilePicture(image)

        if let imageUrl = response.imageUrl {
            uploadedProfileImageUrl = imageUrl
            return
        }

        if response.success {
            return
        }

        profileImage = nil
        uploadedProfileImageUrl = nil
        validationMessage = L10n.apiMessage(response.message) ?? L10n.uploadProfilePhotoFailed
    }

    private func applyExistingProfile(_ profile: SportProfileData) {
        if let leagueRaw = profile.favoriteLeague,
           let league = FootballLeague(rawValue: leagueRaw) {
            selectedLeague = league
            reloadTeamsForSelectedLeague()
        }

        if let team = profile.favoriteTeam, !team.isEmpty {
            selectedTeam = team
        }

        if let footRaw = profile.strongFoot,
           let foot = StrongFoot(rawValue: footRaw) {
            strongFoot = foot
        }

        if let jerseyNumber = profile.jerseyNumber {
            jerseyNumberText = String(jerseyNumber)
        }

        if let experience = profile.experienceLevel,
           let level = ExperienceLevel(rawValue: experience) {
            experienceLevel = level
        }

        selectedPositions = Set(
            (profile.favoritePositions ?? [])
                .compactMap(PlayerPosition.init(rawValue:))
        )

        selectedWeekdays = Set(
            (profile.availabilities ?? [])
                .compactMap(Weekday.init(rawValue:))
        )

        uploadedProfileImageUrl = profile.profileImageUrl
    }

    private func reloadTeamsForSelectedLeague() {
        let teams = referenceDataService.teams(forLeague: selectedLeague.rawValue)
        availableTeams = teams

        if teams.isEmpty {
            selectedTeam = ""
            return
        }

        if !teams.contains(selectedTeam) {
            selectedTeam = teams[0]
        }
    }

    private func buildRequest(profileImageUrl: String?) -> SportProfileRequest {
        let favoritePositions = selectedPositions
            .sorted { $0.displayName < $1.displayName }
            .map(\.rawValue)
        let availabilities = selectedWeekdays
            .sorted { $0.displayName < $1.displayName }
            .map(\.rawValue)

        return SportProfileRequest(
            favoriteLeague: selectedLeague.rawValue,
            favoriteTeam: selectedTeam,
            strongFoot: strongFoot.rawValue,
            experienceLevel: experienceLevel.rawValue,
            jerseyNumber: jerseyNumberValue,
            favoritePositions: favoritePositions,
            playedPositions: favoritePositions,
            availabilities: availabilities,
            profileImageUrl: profileImageUrl
        )
    }
}
