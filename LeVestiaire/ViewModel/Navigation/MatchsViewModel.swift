//
//  MatchsViewModel.swift
//  LeVestaire
//
//  Created by Corentin Robert on 17/06/2026.
//

import Combine
import Foundation

@MainActor
final class MatchsViewModel: ObservableObject {
    @Published private(set) var matches: [MatchItem] = []
    @Published private(set) var isLoading = false
    @Published private(set) var isLoadingMore = false
    @Published private(set) var isRefreshing = false
    @Published private(set) var errorMessage: String?
    @Published var filters = MatchFilters()
    @Published var showsFilters = false
    @Published var showsCreateMatch = false
    @Published var editingMatch: MatchDetail?

    @Published private(set) var userTeams: [SquadTeam] = []

    @Published private(set) var submittingAvailabilityMatchIds: Set<String> = []
    @Published private(set) var isPreparingEditMatch = false
    @Published var availabilityFeedback: String?

    private let matchService: MatchService
    private let teamService: TeamService
    private var currentPage = 1
    private var hasReachedMax = false
    private var loadGeneration = 0
    let pullToRefreshTask = PullToRefreshTask()

    @Published private(set) var totalItems = 0

    var hasActiveFilters: Bool {
        filters.hasActiveFilters
    }

    var activeFilterCount: Int {
        filters.activeFilterCount
    }

    var loadedCountText: String {
        L10n.matchesLoadedCount(matches.count, total: totalItems)
    }

    var showsEndOfListMessage: Bool {
        hasReachedMax && !matches.isEmpty
    }

    var showsTeamFilter: Bool {
        userTeams.count > 1
    }

    func teamName(for id: String) -> String? {
        userTeams.first { $0.id == id }?.name
    }

    init(matchService: MatchService, teamService: TeamService) {
        self.matchService = matchService
        self.teamService = teamService
    }

    convenience init() {
        self.init(matchService: MatchService.shared, teamService: TeamService.shared)
    }

    func initialize() async {
        guard matches.isEmpty else { return }
        async let teamsTask: Void = loadUserTeams()
        async let matchesTask: Void = loadMatches(page: 1, append: false)
        _ = await (teamsTask, matchesTask)
    }

    private func loadUserTeams() async {
        do {
            userTeams = try await teamService.fetchUserTeams()
        } catch {
            userTeams = []
        }
    }

    func refresh() async {
        await executeRefresh()
    }

    func refreshFromPullToRefresh() async {
        await pullToRefreshTask.perform { [weak self] in
            await self?.executeRefresh()
        }
    }

    private func executeRefresh() async {
        await loadMatches(page: 1, append: false, isRefresh: true)
    }

    func loadNextPageIfNeeded(currentMatch: MatchItem) async {
        guard currentMatch.id == matches.last?.id else { return }
        await loadNextPage()
    }

    func loadNextPage() async {
        guard !isLoading, !isLoadingMore, !isRefreshing, !hasReachedMax else { return }
        await loadMatches(page: currentPage + 1, append: true)
    }

    func applyFilters(_ filters: MatchFilters) async {
        self.filters = filters
        await loadMatches(page: 1, append: false)
    }

    func resetFilters() async {
        filters = MatchFilters()
        await loadMatches(page: 1, append: false)
    }

    func isSubmittingAvailability(for matchId: String) -> Bool {
        submittingAvailabilityMatchIds.contains(matchId)
    }

    func submitAvailability(for matchId: String, status: MatchAvailabilityStatus) async {
        guard !submittingAvailabilityMatchIds.contains(matchId) else { return }

        submittingAvailabilityMatchIds.insert(matchId)
        availabilityFeedback = nil
        defer { submittingAvailabilityMatchIds.remove(matchId) }

        do {
            _ = try await matchService.updateMyAvailability(matchId: matchId, status: status)
            let detail = try await matchService.fetchMatch(id: matchId)
            if let index = matches.firstIndex(where: { $0.id == matchId }) {
                matches[index] = detail.toMatchItem().preservingListingContext(
                    from: matches[index],
                    teamNameResolver: teamName(for:)
                )
            }
        } catch let error as MatchServiceError {
            availabilityFeedback = error.errorDescription
        } catch {
            availabilityFeedback = error.localizedDescription
        }
    }

    func insertCreatedMatch(_ detail: MatchDetail) {
        updateMatchInListing(detail, insertIfMissing: true)
    }

    func updateMatchInListing(_ detail: MatchDetail, insertIfMissing: Bool = false) {
        var item = detail.toMatchItem().resolvingHomeTeamName(using: teamName(for:))
        guard !item.id.isEmpty else { return }

        if let index = matches.firstIndex(where: { $0.id == item.id }) {
            item = item.preservingListingContext(from: matches[index], teamNameResolver: teamName(for:))
        }

        if filters.includes(item) {
            if let index = matches.firstIndex(where: { $0.id == item.id }) {
                matches[index] = item
            } else if insertIfMissing {
                matches.insert(item, at: 0)
                totalItems += 1
            }
        } else if let index = matches.firstIndex(where: { $0.id == item.id }) {
            matches.remove(at: index)
            totalItems = max(0, totalItems - 1)
        }
    }

    func refreshMatchInListing(id: String) async {
        guard !id.isEmpty else { return }

        do {
            let detail = try await matchService.fetchMatch(id: id)
            updateMatchInListing(detail)
        } catch {
            // Ignore listing sync errors on back navigation.
        }
    }

    func openEditMatch(id: String) async {
        guard !isPreparingEditMatch else { return }

        isPreparingEditMatch = true
        availabilityFeedback = nil
        defer { isPreparingEditMatch = false }

        do {
            editingMatch = try await matchService.fetchMatch(id: id)
        } catch let error as MatchServiceError {
            availabilityFeedback = error.errorDescription
        } catch {
            availabilityFeedback = error.localizedDescription
        }
    }

    func closeEditMatch() {
        editingMatch = nil
    }

    private func loadMatches(page: Int, append: Bool, isRefresh: Bool = false) async {
        loadGeneration += 1
        let generation = loadGeneration

        if append {
            isLoadingMore = true
        } else if isRefresh, !matches.isEmpty {
            isRefreshing = true
        } else {
            isLoading = true
            errorMessage = nil
        }

        defer {
            if generation == loadGeneration {
                isLoading = false
                isLoadingMore = false
                isRefreshing = false
            }
        }

        do {
            let criteria = MatchFetchCriteria(
                page: page,
                statuses: filters.statuses,
                teamIds: filters.teamIds,
                fromDate: filters.fromDate,
                toDate: filters.toDate
            )
            let response = try await matchService.fetchMatches(criteria: criteria)
            guard generation == loadGeneration else { return }

            let fetchedMatches = response.matches
                .filter { !$0.id.isEmpty }
                .filter { filters.includes($0) }

            if append {
                let existingIDs = Set(matches.map(\.id))
                let newMatches = fetchedMatches.filter { !existingIDs.contains($0.id) }
                matches.append(contentsOf: newMatches)
            } else {
                matches = fetchedMatches
            }

            currentPage = response.pageInfo?.page ?? page
            totalItems = response.pageInfo?.total ?? matches.count
            hasReachedMax = !(response.pageInfo?.hasNextPage ?? false)
            errorMessage = nil
        } catch {
            guard generation == loadGeneration else { return }
            guard !isCancellationError(error) else { return }

            if !append, matches.isEmpty {
                errorMessage = error.localizedDescription
            }
        }
    }

    private func isCancellationError(_ error: Error) -> Bool {
        TaskCancellation.isError(error)
    }
}

#if DEBUG
extension MatchsViewModel {
    func applyPreviewState(
        matches: [MatchItem],
        teams: [SquadTeam],
        filters: MatchFilters = MatchFilters(),
        submittingAvailabilityMatchIds: Set<String> = []
    ) {
        self.matches = matches
        userTeams = teams
        self.filters = filters
        self.submittingAvailabilityMatchIds = submittingAvailabilityMatchIds
        totalItems = matches.count
        currentPage = 1
        hasReachedMax = true
        isLoading = false
        isLoadingMore = false
        isRefreshing = false
        errorMessage = nil
    }
}
#endif
