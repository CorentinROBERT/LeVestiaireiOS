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

    private let sportProfileService: SportProfileService
    private let referenceDataService: ReferenceDataService
    private let authService: AuthService

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
        sportProfileService: SportProfileService,
        referenceDataService: ReferenceDataService,
        authService: AuthService
    ) {
        self.sportProfileService = sportProfileService
        self.referenceDataService = referenceDataService
        self.authService = authService

        reloadTeamsForSelectedLeague()
    }

    convenience init() {
        self.init(
            sportProfileService: SportProfileService.shared,
            referenceDataService: ReferenceDataService.shared,
            authService: AuthService.shared
        )
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
            validationMessage = "Veuillez compléter tous les champs obligatoires."
            return
        }

        isLoading = true

        Task {
            defer { isLoading = false }

            let request = buildRequest(profileImageUrl: uploadedProfileImageUrl)
            let response = await sportProfileService.saveProfile(request)

            guard response.success, response.hasValidData else {
                validationMessage = response.userFacingMessage ?? "Impossible d'enregistrer le profil sportif."
                return
            }

            authService.markSportProfileCompleted()
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
        validationMessage = response.message ?? "Impossible d'envoyer la photo de profil."
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
