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

        isSubmitting = true
        errorMessage = nil
        defer { isSubmitting = false }

        do {
            _ = try await matchService.forcePlayerAvailability(
                matchId: matchId,
                playerId: playerId,
                status: status
            )
            await refreshAvailabilityBoard()
            match = try await matchService.fetchMatch(id: matchId)
            return true
        } catch {
            surfaceError(error)
            return false
        }
    }

    func loadAvailability() async {
        guard showsAvailabilityManagement else { return }
        await refreshAvailabilityBoard()
    }

    func loadAvailabilityIfNeeded() async throws {
        await refreshAvailabilityBoard()
    }

    func refreshAvailabilityBoard() async {
        isLoadingAvailability = true
        defer {
            isLoadingAvailability = false
            hasLoadedAvailability = true
        }

        do {
            let roster = try await matchService.fetchAvailabilityRoster(matchId: matchId)
            availability = roster.resolvedEntries
            availabilityBoardSummary = roster.summary
        } catch {
            availability = []
            availabilityBoardSummary = nil
            surfaceError(error)
        }
    }
}
