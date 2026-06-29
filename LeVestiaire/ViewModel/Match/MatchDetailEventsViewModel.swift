//
//  MatchDetailEventsViewModel.swift
//  LeVestaire
//

import Combine
import Foundation

@MainActor
final class MatchDetailEventsViewModel: ObservableObject {
    @Published var events: [MatchEvent] = []
    @Published var isLoadingEvents = false
    @Published var hasLoadedEvents = false
    @Published var isSubmitting = false

    private weak var host: MatchDetailViewModel?
    private let matchService: any MatchDetailServicing

    init(matchService: any MatchDetailServicing) {
        self.matchService = matchService
    }

    func attach(to host: MatchDetailViewModel) {
        self.host = host
    }

    var canManage: Bool {
        guard let match = host?.match else { return false }
        if match.allowsEventCorrections { return true }
        return match.status == .finished && host?.canManageMatchTeam == true
    }

    var eventPlayerOptions: [MatchEventPlayerOption] {
        host?.eventPlayerOptions ?? []
    }

    var sortedEvents: [MatchEvent] {
        let grouped = events.groupedForTimeline
        return grouped.startEvents + grouped.middleEvents + grouped.endEvents
    }

    func resetCache() {
        hasLoadedEvents = false
        events = []
    }

    func loadContext() async {
        guard canManage else { return }
        await host?.compositionViewModel.loadPlayerDirectory()
    }

    func loadIfNeeded(force: Bool = false) async {
        guard let match = host?.match else { return }
        guard match.status == .ongoing || match.status == .finished else { return }
        guard force || !hasLoadedEvents else { return }

        isLoadingEvents = true
        defer { isLoadingEvents = false }

        do {
            events = try await matchService.fetchEvents(matchId: host?.matchId ?? "")
            hasLoadedEvents = true
        } catch {
            if isCancellationError(error) { return }
            surfaceError(error)
        }
    }

    func create(_ request: CreateMatchEventRequest) async -> Bool {
        guard canManage, let matchId = host?.matchId else { return false }

        isSubmitting = true
        defer { isSubmitting = false }

        do {
            let event = try await matchService.createEvent(matchId: matchId, request: request)
            events = try await matchService.fetchEvents(matchId: matchId)
            host?.match = try await matchService.fetchMatch(id: matchId)
            _ = event
            return true
        } catch {
            surfaceError(error)
            return false
        }
    }

    func delete(_ eventId: String) async -> Bool {
        guard canManage, let matchId = host?.matchId else { return false }
        guard let event = events.first(where: { $0.id == eventId }), event.isDeletable else { return false }

        isSubmitting = true
        defer { isSubmitting = false }

        do {
            try await matchService.deleteEvent(matchId: matchId, eventId: eventId)
            events = try await matchService.fetchEvents(matchId: matchId)
            host?.match = try await matchService.fetchMatch(id: matchId)
            return true
        } catch {
            surfaceError(error)
            return false
        }
    }

    private func surfaceError(_ error: Error) {
        host?.surfaceError(error)
    }

    private func isCancellationError(_ error: Error) -> Bool {
        TaskCancellation.isError(error)
    }
}
