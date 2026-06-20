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
    @Published private(set) var match: MatchDetail?
    @Published private(set) var availability: [MatchAvailabilityEntry] = []
    @Published private(set) var availabilityBoardSummary: AvailabilitySummary?
    @Published private(set) var selectablePlayers: [MatchSelectablePlayer] = []
    @Published private(set) var teamTemplates: [TeamComposition] = []
    @Published private(set) var events: [MatchEvent] = []
    @Published private(set) var matchStats: MatchStatsPayload?
    @Published private(set) var matchQuizzes: [MatchQuizSummary] = []
    @Published private(set) var isLoadingEvents = false
    @Published private(set) var hasLoadedEvents = false
    @Published private(set) var isLoadingMatchStats = false
    @Published private(set) var hasLoadedMatchStats = false
    @Published private(set) var isLoadingQuizzes = false
    @Published private(set) var hasLoadedQuizzes = false
    @Published private(set) var isLoading = false
    @Published private(set) var isLoadingAvailability = false
    @Published private(set) var hasLoadedAvailability = false
    @Published private(set) var isSubmitting = false
    @Published var errorMessage: String?

    private let matchId: String
    private let matchService: MatchService
    private let compositionService: CompositionService

    var uxMode: MatchUXMode {
        match?.uxMode ?? .readOnly
    }

    var showsRespondSection: Bool {
        match?.capabilities.canRespond == true
    }

    var showsPrepareHub: Bool {
        match?.showsPrepareHub ?? false
    }

    var tabConfiguration: MatchDetailTabConfiguration? {
        guard let match else { return nil }
        return MatchDetailTabConfiguration.forMatch(match, showsPrepareHub: showsPrepareHub)
    }

    var publishButtonEnabled: Bool {
        match?.capabilities.canPublish == true
    }

    var publishBlockerMessages: [String] {
        match?.publishBlockers.map(\.localizedMessage) ?? []
    }

    var eventPlayerOptions: [MatchEventPlayerOption] {
        compositionDisplayMembers.compactMap { member in
            let memberKey = member.compositionMemberKey
            guard !memberKey.isEmpty else { return nil }
            return MatchEventPlayerOption(id: memberKey, name: member.displayName)
        }
    }

    var sortedEvents: [MatchEvent] {
        let grouped = events.groupedForTimeline
        return grouped.startEvents + grouped.middleEvents + grouped.endEvents
    }

    var editorMembers: [TeamMember] {
        if match?.composition != nil {
            return compositionDisplayMembers
        }

        return compositionPlayerPool
    }

    private var compositionPlayerPool: [TeamMember] {
        if !selectablePlayers.isEmpty {
            return selectablePlayers.map { $0.asTeamMember() }
        }

        if !availability.isEmpty {
            return availability.map { $0.asSelectablePlayer().asTeamMember() }
        }

        return []
    }

    private var compositionDisplayMembers: [TeamMember] {
        guard let composition = match?.composition else { return compositionPlayerPool }

        let assignments = composition.allAssignments
        let pool = compositionPlayerPool
        var seen = Set<String>()

        return assignments.compactMap { assignment in
            guard let memberId = assignment.resolvedMemberId, !seen.contains(memberId) else {
                return nil
            }
            seen.insert(memberId)

            if let pooledMember = pool.first(where: { $0.matchesCompositionMemberKey(memberId) }) {
                return pooledMember
            }

            let isGuest = CompositionMemberKey.isGuestKey(memberId)
            return TeamMember(
                id: isGuest ? CompositionMemberKey.rawGuestId(from: memberId) : memberId,
                userId: isGuest ? nil : memberId,
                firstName: assignment.firstName,
                lastName: assignment.lastName,
                isGuest: isGuest
            )
        }
    }

    var canEditComposition: Bool {
        match?.capabilities.canManageComposition == true && match?.isCompositionLocked == false
    }

    var canEditMatchInfo: Bool {
        guard let match else { return false }
        return match.status.isPreparationStatus
            && !match.isPreparationLocked
            && (
                match.capabilities.canPublish
                    || match.capabilities.canManageAvailability
                    || match.capabilities.canManageComposition
            )
    }

    var canManageMatchLifecycle: Bool {
        guard let match else { return false }
        return match.status.isPreparationStatus && match.capabilities.canPublish
    }

    var showsAvailabilityManagement: Bool {
        guard let match else { return false }
        return match.capabilities.canManageAvailability || canEditMatchInfo
    }

    init(
        matchId: String,
        matchService: MatchService,
        compositionService: CompositionService
    ) {
        self.matchId = matchId
        self.matchService = matchService
        self.compositionService = compositionService
    }

    convenience init(matchId: String) {
        self.init(
            matchId: matchId,
            matchService: MatchService.shared,
            compositionService: CompositionService.shared
        )
    }

    func load() async {
        isLoading = true
        errorMessage = nil
        resetTabCaches()
        defer { isLoading = false }

        do {
            match = try await matchService.fetchMatch(id: matchId)
            await loadSupplementaryData()
        } catch {
            surfaceError(error)
        }
    }

    func refresh() async {
        await load()
    }

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

    func loadEventContext() async {
        guard match?.capabilities.canManageEvents == true else { return }
        await loadCompositionPlayerDirectory()
    }

    func loadTabContentIfNeeded(_ tab: MatchDetailTab) async {
        switch tab {
        case .composition:
            await loadSelectablePlayers()
        case .events:
            await loadEventsIfNeeded()
        case .statistics:
            await loadMatchStatsIfNeeded()
        case .quiz:
            await loadQuizzesIfNeeded()
        }
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

    func loadMatchStatsIfNeeded(force: Bool = false) async {
        guard let match else { return }
        guard match.status == .ongoing || match.status == .finished else { return }
        guard force || !hasLoadedMatchStats else { return }

        isLoadingMatchStats = true
        defer { isLoadingMatchStats = false }

        do {
            matchStats = try await matchService.fetchMatchStats(matchId: matchId)
            hasLoadedMatchStats = true
        } catch {
            if isCancellationError(error) { return }
            matchStats = nil
            surfaceError(error)
        }
    }

    func loadQuizzesIfNeeded(force: Bool = false) async {
        guard let match else { return }
        guard match.status == .finished else { return }
        guard force || !hasLoadedQuizzes else { return }

        isLoadingQuizzes = true
        defer { isLoadingQuizzes = false }

        do {
            matchQuizzes = try await matchService.fetchQuizzesForMatch(matchId: matchId)
            hasLoadedQuizzes = true
        } catch {
            if isCancellationError(error) { return }
            matchQuizzes = []
            surfaceError(error)
        }
    }

    private func resetTabCaches() {
        hasLoadedEvents = false
        hasLoadedMatchStats = false
        hasLoadedQuizzes = false
        matchStats = nil
        matchQuizzes = []
    }

    func loadAvailability() async {
        guard showsAvailabilityManagement else { return }
        await refreshAvailabilityBoard()
    }

    func loadSelectablePlayers() async {
        await loadCompositionPlayerDirectory()
    }

    private func resolveSelectablePlayersFallback() async -> [MatchSelectablePlayer] {
        if !availability.isEmpty {
            return availability.map { $0.asSelectablePlayer() }
        }

        if showsAvailabilityManagement || match?.composition != nil {
            if let roster = try? await matchService.fetchAvailabilityRoster(matchId: matchId) {
                let memberPlayers = roster.members.map { $0.asSelectablePlayer(isGuest: false) }
                let guestPlayers = roster.guests.map { $0.asSelectablePlayer(isGuest: true) }
                return (memberPlayers + guestPlayers).sorted {
                    $0.displayName.localizedCaseInsensitiveCompare($1.displayName) == .orderedAscending
                }
            }
        }

        return []
    }

    func loadTeamTemplates() async {
        guard let teamId = match?.teamId else { return }

        do {
            teamTemplates = try await compositionService.fetchTeamCompositions(teamId: teamId)
        } catch {
            teamTemplates = []
        }
    }

    func makeCompositionTabDraft() -> CompositionTabDraft {
        makeCompositionTabDrafts().first(where: \.isMain)
            ?? CompositionTabDraft(
                name: match?.title ?? L10n.text("composition"),
                isMain: true
            )
    }

    func makeCompositionTabDrafts() -> [CompositionTabDraft] {
        guard let composition = match?.composition else {
            return [
                CompositionTabDraft(
                    name: match?.title ?? L10n.text("composition"),
                    isMain: true
                )
            ]
        }

        let tabs = CompositionTabDraft.from(composition: composition)
        guard !tabs.isEmpty else {
            return [
                CompositionTabDraft(
                    name: composition.name,
                    formationKey: composition.formation ?? FormationCatalog.defaultFormationKey,
                    isMain: true
                )
            ]
        }
        return tabs
    }

    func saveMatchComposition(
        mainTab: CompositionTabDraft,
        templateCompositionId: String? = nil
    ) async -> Bool {
        guard canEditComposition else { return false }

        let trimmedName = mainTab.name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty else {
            errorMessage = L10n.text("compositionNameRequired")
            return false
        }

        guard mainTab.starterAssignments.count == 7 else {
            errorMessage = L10n.format(
                "compositionMustHave7StartersCurrently",
                mainTab.starterAssignments.count
            )
            return false
        }

        isSubmitting = true
        errorMessage = nil
        defer { isSubmitting = false }

        var tab = mainTab
        tab.name = trimmedName

        let request = MatchCompositionSaveRequest.from(
            tab: tab,
            templateCompositionId: templateCompositionId,
            members: editorMembers,
            alternativeTabs: alternativeTabs(fromTemplateId: templateCompositionId)
        )

        do {
            let updated: MatchDetail
            if match?.composition != nil {
                updated = try await matchService.updateMatchComposition(matchId: matchId, request: request)
            } else {
                updated = try await matchService.createMatchComposition(matchId: matchId, request: request)
            }
            applyMatchUpdate(updated, templateCompositionId: templateCompositionId)
            await loadSupplementaryData()
            return true
        } catch {
            surfaceError(error)
            return false
        }
    }

    func updateMatchInfo(from updatedMatch: MatchDetail) {
        applyMatchUpdate(updatedMatch)
    }

    func cancelMatch() async -> Bool {
        guard canManageMatchLifecycle else { return false }
        return await updateStatus(.cancelled)
    }

    func postponeMatch() async -> Bool {
        guard canManageMatchLifecycle else { return false }
        return await updateStatus(.postponed)
    }

    func lockComposition() async -> Bool {
        guard match?.capabilities.canManageComposition == true else { return false }

        isSubmitting = true
        errorMessage = nil
        defer { isSubmitting = false }

        do {
            let previous = match
            var updated = try await matchService.lockMatchComposition(matchId: matchId)
            if let refreshed = try? await matchService.fetchMatch(id: matchId) {
                updated = refreshed
            }
            if let previous {
                updated = updated.preservingPresentationContext(from: previous)
            }
            match = updated
            await loadSupplementaryData()
            return true
        } catch {
            surfaceError(error)
            return false
        }
    }

    private func applyMatchUpdate(_ updated: MatchDetail, templateCompositionId: String? = nil) {
        var resolved = updated
        if let previous = match {
            resolved = updated.preservingPresentationContext(from: previous)
        }
        if let templateCompositionId,
           let template = teamTemplates.first(where: { $0.id == templateCompositionId }),
           let composition = resolved.composition {
            resolved = resolved.replacingComposition(composition.enrichedWithTemplate(template))
        }
        match = resolved
    }

    private func alternativeTabs(fromTemplateId templateId: String?) -> [CompositionTabDraft] {
        guard let templateId,
              let template = teamTemplates.first(where: { $0.id == templateId }) else {
            return []
        }
        return CompositionTabDraft.from(composition: template).filter { !$0.isMain }
    }

    func publishMatch() async -> Bool {
        guard match?.capabilities.canPublish == true else { return false }

        isSubmitting = true
        errorMessage = nil
        defer { isSubmitting = false }

        do {
            match = try await matchService.publishMatch(id: matchId)
            await loadSupplementaryData()
            return true
        } catch {
            surfaceError(error)
            return false
        }
    }

    func startMatch() async -> Bool {
        guard match?.capabilities.canStartMatch == true else { return false }
        return await updateStatus(.ongoing)
    }

    func finishMatch() async -> Bool {
        guard match?.capabilities.canFinishMatch == true else { return false }
        return await updateStatus(.finished)
    }

    func createEvent(_ request: CreateMatchEventRequest) async -> Bool {
        guard match?.capabilities.canManageEvents == true else { return false }

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
        guard match?.capabilities.canManageEvents == true else { return false }
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

    func updateScore(home: Int, away: Int) async -> Bool {
        guard match?.capabilities.canUpdateScore == true else { return false }

        isSubmitting = true
        errorMessage = nil
        defer { isSubmitting = false }

        do {
            match = try await matchService.updateScore(
                matchId: matchId,
                scoreHome: home,
                scoreAway: away
            )
            return true
        } catch {
            surfaceError(error)
            return false
        }
    }

    private func updateStatus(_ status: MatchStatus) async -> Bool {
        isSubmitting = true
        errorMessage = nil
        defer { isSubmitting = false }

        do {
            match = try await matchService.updateMatchStatus(id: matchId, status: status)
            await loadSupplementaryData()
            return true
        } catch {
            surfaceError(error)
            return false
        }
    }

    private func loadSupplementaryData() async {
        guard let match else { return }

        if showsAvailabilityManagement {
            try? await loadAvailabilityIfNeeded()
        }

        if match.composition != nil || match.capabilities.canManageComposition {
            await loadCompositionPlayerDirectory()
        }

        if match.composition != nil {
            await loadTeamTemplates()
            enrichCompositionFromTeamTemplatesIfNeeded()
        }

        if match.status == .ongoing || match.status == .finished {
            await loadEventsIfNeeded(force: true)
        }
    }

    private func enrichCompositionFromTeamTemplatesIfNeeded() {
        guard let composition = match?.composition,
              composition.alternatives.isEmpty,
              !teamTemplates.isEmpty else { return }

        let template = teamTemplates.first { candidate in
            candidate.hasAlternativeFormations
                && (candidate.name == composition.name
                    || candidate.resolvedStarters.count == composition.resolvedStarters.count)
        }

        if let template {
            match = match?.replacingComposition(composition.enrichedWithTemplate(template))
        }
    }

    private func loadCompositionPlayerDirectory() async {
        do {
            let players = try await matchService.fetchSelectablePlayers(matchId: matchId)
            if !players.isEmpty {
                selectablePlayers = players
                return
            }
        } catch {
            if match?.capabilities.canManageComposition == true {
                surfaceError(error)
            }
        }

        selectablePlayers = await resolveSelectablePlayersFallback()
    }

    private func loadAvailabilityIfNeeded() async throws {
        await refreshAvailabilityBoard()
    }

    private func refreshAvailabilityBoard() async {
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

    private func loadSelectablePlayersIfNeeded() async throws {
        await loadCompositionPlayerDirectory()
    }

    private func surfaceError(_ error: Error) {
        guard !isCancellationError(error) else { return }

        if let matchError = error as? MatchServiceError {
            errorMessage = matchError.errorDescription
        } else {
            errorMessage = error.localizedDescription
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
