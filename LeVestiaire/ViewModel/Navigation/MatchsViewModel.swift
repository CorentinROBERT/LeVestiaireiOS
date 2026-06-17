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

    private let matchService: MatchService
    private var currentPage = 1
    private var hasReachedMax = false
    private var loadGeneration = 0

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

    init(matchService: MatchService) {
        self.matchService = matchService
    }

    convenience init() {
        self.init(matchService: MatchService.shared)
    }

    func initialize() async {
        guard matches.isEmpty else { return }
        await loadMatches(page: 1, append: false)
    }

    func refresh() async {
        await loadMatches(page: 1, append: false, isRefresh: true)
    }

    func loadNextPageIfNeeded(currentMatch: MatchItem) async {
        guard currentMatch.id == matches.last?.id else { return }
        await loadNextPage()
    }

    func loadNextPage() async {
        guard !isLoading, !isLoadingMore, !hasReachedMax else { return }
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
                fromDate: filters.fromDate,
                toDate: filters.toDate
            )
            let response = try await matchService.fetchMatches(criteria: criteria)
            guard generation == loadGeneration else { return }

            let fetchedMatches = response.matches.filter { !$0.id.isEmpty }

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
        if error is CancellationError {
            return true
        }

        if let urlError = error as? URLError, urlError.code == .cancelled {
            return true
        }

        return false
    }
}
