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
    @Published var isLoading = false
    @Published var isSubmitting = false
    @Published var isSubmittingLifecycle = false
    @Published var errorMessage: String?
    @Published var canManageMatchTeam = false

    let matchId: String
    let matchService: MatchService
    let compositionService: CompositionService
    let teamService: TeamService
    let authService: AuthService
    let availabilityViewModel: MatchDetailAvailabilityViewModel
    let compositionViewModel: MatchDetailCompositionViewModel
    let quizViewModel: MatchDetailQuizViewModel
    let eventsViewModel: MatchDetailEventsViewModel
    let statisticsViewModel: MatchDetailStatisticsViewModel

    let pullToRefreshTask = PullToRefreshTask()

    var currentUserId: String? {
        authService.currentUser?.id
    }

    init(
        matchId: String,
        matchService: MatchService,
        compositionService: CompositionService,
        teamService: TeamService,
        authService: AuthService,
        availabilityViewModel: MatchDetailAvailabilityViewModel? = nil,
        compositionViewModel: MatchDetailCompositionViewModel? = nil,
        quizViewModel: MatchDetailQuizViewModel? = nil,
        eventsViewModel: MatchDetailEventsViewModel? = nil,
        statisticsViewModel: MatchDetailStatisticsViewModel? = nil
    ) {
        self.matchId = matchId
        self.matchService = matchService
        self.compositionService = compositionService
        self.teamService = teamService
        self.authService = authService
        self.availabilityViewModel = availabilityViewModel ?? MatchDetailAvailabilityViewModel(
            matchService: matchService
        )
        self.compositionViewModel = compositionViewModel ?? MatchDetailCompositionViewModel(
            matchService: matchService,
            compositionService: compositionService
        )
        self.quizViewModel = quizViewModel ?? MatchDetailQuizViewModel(
            quizService: QuizService.shared,
            teamService: teamService
        )
        self.eventsViewModel = eventsViewModel ?? MatchDetailEventsViewModel(
            matchService: matchService
        )
        self.statisticsViewModel = statisticsViewModel ?? MatchDetailStatisticsViewModel(
            matchService: matchService
        )
        self.availabilityViewModel.attach(to: self)
        self.compositionViewModel.attach(to: self)
        self.quizViewModel.attach(to: self)
        self.eventsViewModel.attach(to: self)
        self.statisticsViewModel.attach(to: self)
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

        await executeRefresh()
    }

    /// Pull-to-refresh : le travail réseau doit survivre à l'annulation du geste SwiftUI.
    func refreshFromPullToRefresh() async {
        await pullToRefreshTask.perform { [weak self] in
            await self?.executeRefresh()
        }
    }

    private func executeRefresh() async {
        errorMessage = nil

        do {
            match = try await matchService.fetchMatch(id: matchId)
            await resolveTeamManagementAccess()
        } catch {
            if isCancellationError(error) { return }
            surfaceError(error)
            return
        }

        if match?.showsPrepareHub == true {
            availabilityViewModel.availabilityBoardSummary = match?.availabilitySummary
            await reloadPreparationContent(force: true)
        } else {
            await loadSupplementaryData()
            if shouldRefreshAvailabilityRoster {
                await availabilityViewModel.refreshBoard(force: true)
            }
        }

        if showsRespondSection {
            await availabilityViewModel.refreshMyAvailabilityStatus()
        }

        if availabilityViewModel.showsPresentMembersList {
            await availabilityViewModel.refreshPresentMembers()
        }

        await reloadAllTabContent(force: true)
    }

    func refresh() async {
        await refreshFromPullToRefresh()
    }

    var shouldRefreshAvailabilityRoster: Bool {
        guard let match, match.status.isPreparationStatus else { return false }
        return showsAvailabilityManagement
    }

    func surfaceError(_ error: Error) {
        guard !isCancellationError(error) else { return }

        if let matchError = error as? MatchServiceError {
            errorMessage = matchError.errorDescription
        } else if let quizError = error as? QuizServiceError {
            errorMessage = quizError.errorDescription
        } else {
            errorMessage = error.localizedDescription
        }
    }

    func isCancellationError(_ error: Error) -> Bool {
        TaskCancellation.isError(error)
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
