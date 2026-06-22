//
//  MatchDetailAvailabilityViewModel.swift
//  LeVestaire
//

import Combine
import Foundation

@MainActor
final class MatchDetailAvailabilityViewModel: ObservableObject {
    @Published var availability: [MatchAvailabilityEntry] = []
    @Published var availabilityBoardSummary: AvailabilitySummary?
    @Published var isLoadingAvailability = false
    @Published var hasLoadedAvailability = false
    @Published var isUpdatingAvailability = false
    @Published var isSubmitting = false

    private weak var host: MatchDetailViewModel?
    private let matchService: MatchService

    init(matchService: MatchService) {
        self.matchService = matchService
    }

    func attach(to host: MatchDetailViewModel) {
        self.host = host
    }

    var showsManagement: Bool {
        host?.showsAvailabilityManagement == true
    }

    func resetCache() {
        hasLoadedAvailability = false
        availability = []
        availabilityBoardSummary = nil
    }

    func submitMyAvailability(_ status: MatchAvailabilityStatus) async -> Bool {
        guard host?.match?.capabilities.canRespond == true,
              let matchId = host?.matchId else { return false }

        isSubmitting = true
        defer { isSubmitting = false }

        do {
            _ = try await matchService.updateMyAvailability(matchId: matchId, status: status)
            host?.match = try await matchService.fetchMatch(id: matchId)
            return true
        } catch {
            surfaceError(error)
            return false
        }
    }

    func forcePlayerAvailability(
        playerId: String,
        status: MatchAvailabilityStatus
    ) async -> Bool {
        guard showsManagement,
              let matchId = host?.matchId else { return false }
        guard let entry = availability.first(where: { matchesAvailabilityTarget($0, playerId: playerId) }),
              entry.canForceAvailability else {
            return false
        }

        isUpdatingAvailability = true
        defer { isUpdatingAvailability = false }

        do {
            let updatedEntry = try await matchService.forcePlayerAvailability(
                matchId: matchId,
                playerId: playerId,
                status: status
            )
            applyAvailabilityEntryUpdate(updatedEntry)
            await refreshBoard(force: true, silent: true)
            syncMatchAvailabilitySummaryFromBoard()
            return true
        } catch {
            surfaceError(error)
            return false
        }
    }

    func loadIfNeeded() async {
        guard showsManagement, !hasLoadedAvailability else { return }
        await refreshBoard()
    }

    func refreshMyAvailabilityStatus() async {
        guard host?.showsRespondSection == true,
              let matchId = host?.matchId else { return }

        do {
            let response = try await matchService.fetchMyAvailability(matchId: matchId)
            if let current = host?.match {
                host?.match = current.replacingMyAvailabilityStatus(response.status)
            }
        } catch {
            if !isCancellationError(error) {
                surfaceError(error)
            }
        }
    }

    func refreshBoard(force: Bool = false, silent: Bool = false) async {
        guard force || showsManagement else { return }

        if !silent {
            isLoadingAvailability = true
        }
        defer {
            if !silent {
                isLoadingAvailability = false
            }
            hasLoadedAvailability = true
        }

        do {
            let roster = try await matchService.fetchAvailabilityRoster(matchId: host?.matchId ?? "")
            availability = roster.resolvedBoardEntries
            availabilityBoardSummary = roster.summary ?? host?.match?.availabilitySummary
            syncMatchAvailabilitySummaryFromBoard()
        } catch {
            if isCancellationError(error) { return }
            if !force {
                availability = []
                availabilityBoardSummary = nil
            }
            surfaceError(error)
        }
    }

    private func applyAvailabilityEntryUpdate(_ updatedEntry: MatchAvailabilityEntry) {
        guard let index = availability.firstIndex(where: { $0.matchesPlayer(updatedEntry) }) else { return }
        var entries = availability
        entries[index] = entries[index].merged(with: updatedEntry)
        availability = entries
    }

    private func syncMatchAvailabilitySummaryFromBoard() {
        guard let summary = availabilityBoardSummary, let current = host?.match else { return }
        host?.match = current.replacingAvailabilitySummary(summary)
    }

    private func matchesAvailabilityTarget(_ entry: MatchAvailabilityEntry, playerId: String) -> Bool {
        let targetIds = Set([playerId].filter { !$0.isEmpty })
        let entryIds = Set([entry.playerId, entry.userId, entry.memberId, entry.availabilityRequestId]
            .compactMap { $0 }
            .filter { !$0.isEmpty })
        return !targetIds.isDisjoint(with: entryIds)
    }

    private func surfaceError(_ error: Error) {
        host?.surfaceError(error)
    }

    private func isCancellationError(_ error: Error) -> Bool {
        TaskCancellation.isError(error)
    }
}
