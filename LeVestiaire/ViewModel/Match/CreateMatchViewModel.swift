//
//  CreateMatchViewModel.swift
//  LeVestaire
//

import Combine
import Foundation

@MainActor
final class CreateMatchViewModel: ObservableObject {
    @Published var opponentTeam = ""
    @Published var location = ""
    @Published var matchDate = Date()
    @Published var matchTime = Date()
    @Published var selectedTeamId: String?
    @Published var description = ""

    @Published private(set) var teams: [SquadTeam] = []
    @Published private(set) var isLoadingTeams = false
    @Published private(set) var isSubmitting = false
    @Published var errorMessage: String?

    private let matchService: MatchService
    private let teamService: TeamService
    private let authService: AuthService

    private var currentUserId: String? {
        authService.currentUser?.id
    }

    var manageableTeams: [SquadTeam] {
        teams.filter { team in
            team.userCanManageTeam(userId: currentUserId) && team.isActive != false
        }
    }

    var hasInactiveManageableTeams: Bool {
        teams.contains { team in
            team.userCanManageTeam(userId: currentUserId) && team.isActive == false
        }
    }

    var showsTeamPicker: Bool {
        manageableTeams.count > 1
    }

    var canSubmit: Bool {
        !isSubmitting
            && !opponentTeam.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            && !location.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            && selectedTeamId != nil
            && !isDateTooFarInFuture
    }

    private var isDateTooFarInFuture: Bool {
        guard let maxDate = Calendar.current.date(byAdding: .year, value: 1, to: Date()) else {
            return false
        }
        return matchDate > maxDate
    }

    init(matchService: MatchService, teamService: TeamService, authService: AuthService) {
        self.matchService = matchService
        self.teamService = teamService
        self.authService = authService
    }

    convenience init() {
        self.init(
            matchService: MatchService.shared,
            teamService: TeamService.shared,
            authService: AuthService.shared
        )
    }

    func loadTeams(force: Bool = false) async {
        if !force, !teams.isEmpty {
            ensureDefaultTeamSelection()
            return
        }

        isLoadingTeams = true
        errorMessage = nil
        defer { isLoadingTeams = false }

        do {
            teams = try await teamService.fetchUserTeams()
            ensureDefaultTeamSelection()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func createMatch() async -> MatchDetail? {
        guard canSubmit, let teamId = selectedTeamId else { return nil }

        isSubmitting = true
        errorMessage = nil
        defer { isSubmitting = false }

        let trimmedOpponent = opponentTeam.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedLocation = location.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedDescription = description.trimmingCharacters(in: .whitespacesAndNewlines)

        do {
            return try await matchService.createMatch(
                request: CreateMatchRequest(
                    opponentTeam: trimmedOpponent,
                    location: trimmedLocation,
                    date: MatchService.apiDateString(from: matchDate),
                    homeTeam: teamId,
                    title: defaultTitle(opponent: trimmedOpponent),
                    description: trimmedDescription.isEmpty ? nil : trimmedDescription,
                    time: MatchService.apiTimeString(from: matchTime)
                )
            )
        } catch {
            errorMessage = error.localizedDescription
            return nil
        }
    }

    private func ensureDefaultTeamSelection() {
        let manageableIds = Set(manageableTeams.map(\.id))
        if let selectedTeamId, manageableIds.contains(selectedTeamId) {
            return
        }
        selectedTeamId = manageableTeams.first?.id
    }

    private func defaultTitle(opponent: String) -> String {
        "\(L10n.vs) \(opponent)"
    }
}
