//
//  MatchDetailViewModel.swift
//  LeVestaire
//

import Combine
import Foundation

struct MatchEventPlayerOption: Identifiable, Hashable {
    let id: String
    let name: String
}

@MainActor
final class MatchDetailViewModel: ObservableObject {
    @Published var match: MatchDetail?
    @Published var availability: [MatchAvailabilityEntry] = []
    @Published var availabilityBoardSummary: AvailabilitySummary?
    @Published var selectablePlayers: [MatchSelectablePlayer] = []
    @Published var teamTemplates: [TeamComposition] = []
    @Published var events: [MatchEvent] = []
    @Published var matchStats: MatchStatsPayload?
    @Published var matchQuizzes: [MatchQuizSummary] = []
    @Published var isLoadingEvents = false
    @Published var hasLoadedEvents = false
    @Published var isLoadingMatchStats = false
    @Published var hasLoadedMatchStats = false
    @Published var isLoadingQuizzes = false
    @Published var hasLoadedQuizzes = false
    @Published var isLoading = false
    @Published var isLoadingAvailability = false
    @Published var hasLoadedAvailability = false
    @Published var isSubmitting = false
    @Published var errorMessage: String?
    @Published var canManageMatchTeam = false

    let matchId: String
    let matchService: MatchService
    let compositionService: CompositionService
    let teamService: TeamService
    let authService: AuthService

    var currentUserId: String? {
        authService.currentUser?.id
    }

    init(
        matchId: String,
        matchService: MatchService,
        compositionService: CompositionService,
        teamService: TeamService,
        authService: AuthService
    ) {
        self.matchId = matchId
        self.matchService = matchService
        self.compositionService = compositionService
        self.teamService = teamService
        self.authService = authService
    }

    convenience init(matchId: String) {
        self.init(
            matchId: matchId,
            matchService: MatchService.shared,
            compositionService: CompositionService.shared,
            teamService: TeamService.shared,
            authService: AuthService.shared
        )
    }

    func load() async {
        isLoading = true
        errorMessage = nil
        resetTabCaches()
        defer { isLoading = false }

        do {
            match = try await matchService.fetchMatch(id: matchId)
            await resolveTeamManagementAccess()
            await loadSupplementaryData()
        } catch {
            surfaceError(error)
        }
    }

    func refresh() async {
        await load()
    }

    func surfaceError(_ error: Error) {
        guard !isCancellationError(error) else { return }

        if let matchError = error as? MatchServiceError {
            errorMessage = matchError.errorDescription
        } else {
            errorMessage = error.localizedDescription
        }
    }

    func isCancellationError(_ error: Error) -> Bool {
        if error is CancellationError {
            return true
        }

        if let urlError = error as? URLError, urlError.code == .cancelled {
            return true
        }

        return false
    }

#if DEBUG
    func applyPreviewState(
        match: MatchDetail,
        canManageMatchTeam: Bool = false
    ) {
        self.match = match
        self.canManageMatchTeam = canManageMatchTeam
    }
#endif
}
