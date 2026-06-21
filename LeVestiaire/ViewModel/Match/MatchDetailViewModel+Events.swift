//
//  MatchDetailViewModel+Events.swift
//  LeVestaire
//

import Foundation

extension MatchDetailViewModel {
    func loadEventContext() async {
        guard canManageMatchEvents else { return }
        await loadCompositionPlayerDirectory()
    }

    func loadEventsIfNeeded(force: Bool = false) async {
        guard let match else { return }
        guard match.status == .ongoing || match.status == .finished else { return }
        guard force || !hasLoadedEvents else { return }

        isLoadingEvents = true
        defer { isLoadingEvents = false }

        do {
            events = try await matchService.fetchEvents(matchId: matchId)
            hasLoadedEvents = true
        } catch {
            if isCancellationError(error) { return }
            surfaceError(error)
        }
    }

    func createEvent(_ request: CreateMatchEventRequest) async -> Bool {
        guard canManageMatchEvents else { return false }

        isSubmitting = true
        errorMessage = nil
        defer { isSubmitting = false }

        do {
            let event = try await matchService.createEvent(matchId: matchId, request: request)
            events = try await matchService.fetchEvents(matchId: matchId)
            match = try await matchService.fetchMatch(id: matchId)
            _ = event
            return true
        } catch {
            surfaceError(error)
            return false
        }
    }

    func deleteEvent(_ eventId: String) async -> Bool {
        guard canManageMatchEvents else { return false }
        guard let event = events.first(where: { $0.id == eventId }), event.isDeletable else { return false }

        isSubmitting = true
        errorMessage = nil
        defer { isSubmitting = false }

        do {
            try await matchService.deleteEvent(matchId: matchId, eventId: eventId)
            events = try await matchService.fetchEvents(matchId: matchId)
            match = try await matchService.fetchMatch(id: matchId)
            return true
        } catch {
            surfaceError(error)
            return false
        }
    }
}
