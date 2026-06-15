//
//  SportProfileViewModel.swift
//  LeVestaire
//
//  Created by Corentin Robert on 14/06/2026.
//

import Combine
import Foundation
import UIKit

final class SportProfileViewModel: ObservableObject {
    @Published var profileImage: UIImage?
    @Published var strongFoot: StrongFoot = .right
    @Published var jerseyNumberText = ""
    @Published var selectedLeague: FootballLeague = .ligue1
    @Published var selectedTeam = ""
    @Published var selectedPositions: Set<PlayerPosition> = []
    @Published var experienceLevel: ExperienceLevel = .beginner
    @Published var selectedWeekdays: Set<Weekday> = []
    @Published var validationMessage: String?

    var availableTeams: [String] {
        selectedLeague.teams
    }

    var canSubmit: Bool {
        !selectedTeam.isEmpty
            && !selectedPositions.isEmpty
            && !selectedWeekdays.isEmpty
            && jerseyNumberValue != nil
    }

    var jerseyNumberValue: Int? {
        guard let value = Int(jerseyNumberText.trimmingCharacters(in: .whitespaces)),
              (0...999).contains(value) else {
            return nil
        }
        return value
    }

    init() {
        selectedTeam = selectedLeague.teams.first ?? ""
    }

    func onLeagueChanged() {
        if !selectedLeague.teams.contains(selectedTeam) {
            selectedTeam = selectedLeague.teams.first ?? ""
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

        // TODO: envoyer le profil sportif à l'API
    }
}
