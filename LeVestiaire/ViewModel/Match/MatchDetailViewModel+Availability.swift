//
//  MatchDetailViewModel+Availability.swift
//  LeVestaire
//

import Foundation

extension MatchDetailViewModel {
    func submitMyAvailability(_ status: MatchAvailabilityStatus) async -> Bool {
        guard match?.capabilities.canRespond == true else { return false }

        isSubmitting = true
        errorMessage = nil
        defer { isSubmitting = false }

        do {
            _ = try await matchService.updateMyAvailability(matchId: matchId, status: status)
            match = try await matchService.fetchMatch(id: matchId)
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
        guard showsAvailabilityManagement else { return false }
        guard let entry = availability.first(where: { matchesAvailabilityTarget($0, playerId: playerId) }),
              entry.canForceAvailability else {
            return false
        }

        isSubmitting = true
        errorMessage = nil
        defer { isSubmitting = false }

        do {
            let updatedEntry = try await matchService.forcePlayerAvailability(
                matchId: matchId,
                playerId: playerId,
                status: status
            )
            applyAvailabilityEntryUpdate(updatedEntry)
            await refreshAvailabilityBoard(force: true, silent: true)
            syncMatchAvailabilitySummaryFromBoard()
            return true
        } catch {
            surfaceError(error)
            return false
        }
    }

    func loadAvailabilityIfNeeded() async {
        guard showsAvailabilityManagement, !hasLoadedAvailability else { return }
        await refreshAvailabilityBoard()
    }

    func refreshMyAvailabilityStatus() async {
        guard showsRespondSection else { return }

        do {
            let response = try await matchService.fetchMyAvailability(matchId: matchId)
            if let current = match {
                match = current.replacingMyAvailabilityStatus(response.status)
            }
        } catch {
            if !isCancellationError(error) {
                surfaceError(error)
            }
        }
    }

    func refreshAvailabilityBoard(force: Bool = false, silent: Bool = false) async {
        guard force || showsAvailabilityManagement else { return }

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
            let roster = try await matchService.fetchAvailabilityRoster(matchId: matchId)
            availability = roster.resolvedBoardEntries
            availabilityBoardSummary = roster.summary ?? match?.availabilitySummary
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
        guard let summary = availabilityBoardSummary, let current = match else { return }
        match = current.replacingAvailabilitySummary(summary)
    }

    private func matchesAvailabilityTarget(_ entry: MatchAvailabilityEntry, playerId: String) -> Bool {
        let targetIds = Set([playerId].filter { !$0.isEmpty })
        let entryIds = Set([entry.playerId, entry.userId, entry.memberId, entry.availabilityRequestId]
            .compactMap { $0 }
            .filter { !$0.isEmpty })
        return !targetIds.isDisjoint(with: entryIds)
    }
}
