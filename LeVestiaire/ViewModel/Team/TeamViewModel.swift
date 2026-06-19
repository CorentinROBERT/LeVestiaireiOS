//
//  TeamViewModel.swift
//  LeVestaire
//

import Combine
import Foundation
import UIKit

@MainActor
final class TeamViewModel: ObservableObject {
    @Published private(set) var teams: [SquadTeam] = []
    @Published var selectedTeamId: String = ""
    @Published private(set) var selectedTeam: SquadTeam?
    @Published private(set) var compositions: [TeamComposition] = []
    @Published private(set) var teamSeasonStats: TeamSeasonStatsPayload?
    @Published private(set) var teamRankings: TeamSeasonRankings?
    @Published private(set) var teamInvitations: [TeamInvitation] = []
    @Published private(set) var availableSeasons: [String] = []
    @Published var selectedStatsSeason = ""
    @Published var selectedRankingSeason = ""
    @Published var selectedRankingKind: TeamRankingKind = .scorers

    @Published private(set) var isLoading = false
    @Published private(set) var isRefreshingTeam = false
    @Published private(set) var isLoadingStats = false
    @Published private(set) var isLoadingRankings = false
    @Published private(set) var isLoadingInvitations = false
    @Published private(set) var isSubmitting = false

    @Published var invitationPendingCancellation: TeamInvitation?
    @Published var memberPendingRemoval: TeamMember?
    @Published var compositionPendingDeletion: TeamComposition?

    @Published private(set) var compositionsLoadError: String?
    @Published private(set) var invitationsLoadError: String?
    @Published private(set) var statsLoadError: String?
    @Published private(set) var rankingsLoadError: String?

    @Published var activeSheet: TeamSheet?
    @Published var editingComposition: TeamComposition?
    @Published var alertMessage: String?
    @Published var toastMessage: String?
    @Published var errorMessage: String?

    private var seasonsTeamId: String?
    private var statsLoadedForTeamId: String?
    private var rankingsLoadedForTeamId: String?
    private var compositionsLoadedForTeamId: String?

    private let teamService: TeamService
    private let compositionService: CompositionService
    private let statsService: StatsService
    private let selectedTeamStore: SelectedTeamStore
    private let authService: AuthService

    init(
        teamService: TeamService,
        compositionService: CompositionService,
        statsService: StatsService,
        selectedTeamStore: SelectedTeamStore,
        authService: AuthService
    ) {
        self.teamService = teamService
        self.compositionService = compositionService
        self.statsService = statsService
        self.selectedTeamStore = selectedTeamStore
        self.authService = authService
    }

    convenience init() {
        self.init(
            teamService: .shared,
            compositionService: .shared,
            statsService: .shared,
            selectedTeamStore: .shared,
            authService: .shared
        )
    }

    var hasTeams: Bool { !teams.isEmpty }

    var currentUserRole: TeamRole? {
        selectedTeam?.currentUserRole
            ?? selectedTeam?.resolvedMembers.first(where: { member in
                member.userId == authService.currentUser?.id
            })?.role
    }

    var canManageTeam: Bool {
        currentUserRole?.canManageTeam == true
    }

    var statsKPIsUnavailable: Bool {
        TeamKPIDisplay.statsUnavailable(
            stats: teamSeasonStats,
            hasError: statsLoadError != nil,
            isLoading: isLoadingStats
        )
    }

    var kpiMatchesPlayedDisplay: String {
        TeamKPIDisplay.matchesPlayed(
            stats: teamSeasonStats,
            hasError: statsLoadError != nil,
            isLoading: isLoadingStats
        )
    }

    var kpiGoalsDisplay: String {
        TeamKPIDisplay.goals(
            stats: teamSeasonStats,
            hasError: statsLoadError != nil,
            isLoading: isLoadingStats
        )
    }

    var kpiAssistsDisplay: String {
        TeamKPIDisplay.assists(
            stats: teamSeasonStats,
            hasError: statsLoadError != nil,
            isLoading: isLoadingStats
        )
    }

    var kpiMemberCountDisplay: String {
        "\(selectedTeam?.resolvedMemberCount ?? 0)"
    }

    var isLoadingKPIs: Bool { isLoadingStats && teamSeasonStats == nil }

    var showsTeamDetailError: Bool {
        hasTeams && selectedTeam == nil && errorMessage != nil
    }

    func loadInitialData() async {
        errorMessage = nil
        isLoading = true
        defer { isLoading = false }

        do {
            let response = try await teamService.fetchMyTeams()
            teams = response.teams
            restoreSelection()
            await refreshSelectedTeamContent()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func refresh(currentTab: TeamContentTab = .roster) async {
        invalidateLazyTabLoads()
        await loadInitialData()
        await loadTabContentIfNeeded(currentTab, force: true)
    }

    func onTeamSelectionChanged() async {
        selectedTeamStore.selectedTeamId = selectedTeamId
        invalidateLazyTabLoads()
        await refreshSelectedTeamContent()
    }

    func loadTabContentIfNeeded(_ tab: TeamContentTab, force: Bool = false) async {
        guard !selectedTeamId.isEmpty else { return }

        switch tab {
        case .roster:
            break
        case .stats:
            if force || statsLoadedForTeamId != selectedTeamId {
                await loadTeamStats()
                statsLoadedForTeamId = selectedTeamId
            }
        case .rankings:
            if force || rankingsLoadedForTeamId != selectedTeamId {
                await loadTeamRankings()
                rankingsLoadedForTeamId = selectedTeamId
            }
        case .compositions:
            if force || compositionsLoadedForTeamId != selectedTeamId {
                await loadCompositions()
                compositionsLoadedForTeamId = selectedTeamId
            }
        }
    }

    func retryTeamDetail() async {
        await refreshSelectedTeamContent()
    }

    func retryStats() async {
        await loadTeamStats()
        statsLoadedForTeamId = selectedTeamId
    }

    func retryRankings() async {
        await loadTeamRankings()
        rankingsLoadedForTeamId = selectedTeamId
    }

    func retryCompositions() async {
        await loadCompositions()
        compositionsLoadedForTeamId = selectedTeamId
    }

    func retryInvitations() async {
        await loadTeamInvitations()
    }

    func confirmDeleteComposition(_ composition: TeamComposition) {
        compositionPendingDeletion = composition
    }

    func deletePendingComposition() async {
        guard let composition = compositionPendingDeletion else { return }
        compositionPendingDeletion = nil
        _ = await deleteComposition(composition)
    }

    private func showSuccess(_ message: String) {
        toastMessage = message
        TeamHaptics.success()
    }

    private func showError(_ message: String) {
        alertMessage = message
    }

    private func invalidateLazyTabLoads() {
        statsLoadedForTeamId = nil
        rankingsLoadedForTeamId = nil
        compositionsLoadedForTeamId = nil
    }

    func createTeam(name: String, description: String?, logo: UIImage?) async -> Bool {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmedName.count >= 2 else {
            showError(L10n.text("teamNameMinLength"))
            return false
        }

        isSubmitting = true
        defer { isSubmitting = false }

        do {
            let team = try await teamService.createTeam(
                name: trimmedName,
                description: description?.nilIfWhitespace,
                logo: logo
            )
            teams.append(team)
            selectedTeamId = team.id
            selectedTeamStore.selectedTeamId = team.id
            await refreshSelectedTeamContent()
            showSuccess(L10n.format("teamCreatedSuccessfully", team.name))
            return true
        } catch {
            showError(error.localizedDescription)
            return false
        }
    }

    func updateTeam(name: String, description: String?, logo: UIImage?) async -> Bool {
        guard let teamId = selectedTeam?.id else { return false }

        isSubmitting = true
        defer { isSubmitting = false }

        do {
            let team = try await teamService.updateTeam(
                id: teamId,
                name: name.nilIfWhitespace,
                description: description?.nilIfWhitespace,
                logo: logo
            )
            replaceTeam(team)
            showSuccess(L10n.text("successTeamUpdated"))
            return true
        } catch {
            showError(error.localizedDescription)
            return false
        }
    }

    func deleteSelectedTeam() async -> Bool {
        guard let teamId = selectedTeam?.id else { return false }

        isSubmitting = true
        defer { isSubmitting = false }

        do {
            try await teamService.deleteTeam(id: teamId)
            teams.removeAll { $0.id == teamId }
            restoreSelection()
            await refreshSelectedTeamContent()
            showSuccess(L10n.text("teamDeletedSuccessfully"))
            return true
        } catch {
            showError(error.localizedDescription)
            return false
        }
    }

    func leaveSelectedTeam() async -> Bool {
        guard let teamId = selectedTeam?.id else { return false }

        isSubmitting = true
        defer { isSubmitting = false }

        do {
            try await teamService.leaveTeam(id: teamId)
            teams.removeAll { $0.id == teamId }
            restoreSelection()
            await refreshSelectedTeamContent()
            showSuccess(L10n.text("quitterEquipeSucces"))
            return true
        } catch {
            showError(error.localizedDescription)
            return false
        }
    }

    func invitePlayer(email: String, firstName: String, lastName: String?) async -> Bool {
        guard let teamId = selectedTeam?.id else { return false }

        let trimmedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedFirstName = firstName.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !trimmedEmail.isEmpty else {
            showError(L10n.text("enterEmail"))
            return false
        }

        guard !trimmedFirstName.isEmpty else {
            showError(L10n.text("firstNameRequired"))
            return false
        }

        isSubmitting = true
        defer { isSubmitting = false }

        do {
            try await teamService.invitePlayer(
                teamId: teamId,
                email: trimmedEmail,
                firstName: trimmedFirstName,
                lastName: lastName?.nilIfWhitespace
            )
            await loadTeamInvitations()
            showSuccess(L10n.text("invitationSentSuccessfully"))
            return true
        } catch {
            showError(error.localizedDescription)
            return false
        }
    }

    func addGuest(
        firstName: String,
        lastName: String?,
        email: String?,
        jerseyNumber: Int?
    ) async -> Bool {
        guard let teamId = selectedTeam?.id else { return false }

        let trimmedFirstName = firstName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedFirstName.isEmpty else {
            showError(L10n.text("firstNameRequired"))
            return false
        }

        if let jerseyNumber, !(1...99).contains(jerseyNumber) {
            showError(L10n.text("jerseyNumberRange"))
            return false
        }

        isSubmitting = true
        defer { isSubmitting = false }

        do {
            try await teamService.addGuest(
                teamId: teamId,
                request: CreateGuestRequest(
                    firstName: trimmedFirstName,
                    lastName: lastName?.nilIfWhitespace,
                    email: email?.nilIfWhitespace,
                    jerseyNumber: jerseyNumber,
                    notes: nil
                )
            )
            await refreshSelectedTeamContent()
            showSuccess(L10n.text("guestAdded"))
            return true
        } catch {
            showError(error.localizedDescription)
            return false
        }
    }

    func resendInvitation(_ invitation: TeamInvitation) async {
        guard invitation.status.canManage else { return }

        do {
            try await teamService.resendInvitation(invitationId: invitation.id)
            await loadTeamInvitations()
            showSuccess(L10n.text("invitationResent"))
        } catch {
            showError(error.localizedDescription)
        }
    }

    func confirmCancelInvitation(_ invitation: TeamInvitation) {
        invitationPendingCancellation = invitation
    }

    func cancelInvitation() async {
        guard let invitation = invitationPendingCancellation else { return }
        invitationPendingCancellation = nil

        do {
            try await teamService.cancelInvitation(invitationId: invitation.id)
            await loadTeamInvitations()
            showSuccess(L10n.text("invitationCancelled"))
        } catch {
            showError(error.localizedDescription)
        }
    }

    func updateMemberRole(memberId: String, role: TeamRole) async {
        guard let teamId = selectedTeam?.id else { return }

        do {
            try await teamService.updateMemberRole(teamId: teamId, memberId: memberId, role: role)
            await refreshSelectedTeamContent()
            showSuccess(L10n.format("roleUpdatedTo", role.localizedLabel))
        } catch {
            showError(error.localizedDescription)
        }
    }

    func confirmRemoveMember(_ member: TeamMember) {
        memberPendingRemoval = member
    }

    func removeMember() async {
        guard let member = memberPendingRemoval else { return }
        memberPendingRemoval = nil
        await removeMember(memberId: member.id, isGuest: member.isGuest)
    }

    func removeMember(memberId: String, isGuest: Bool = false) async {
        guard let teamId = selectedTeam?.id else { return }

        let memberIsGuest = isGuest
            || selectedTeam?.resolvedMembers.first(where: { $0.id == memberId })?.isGuest == true

        do {
            if memberIsGuest {
                try await teamService.deleteGuest(guestId: memberId)
            } else {
                try await teamService.removeMember(teamId: teamId, memberId: memberId)
            }
            await refreshSelectedTeamContent()
            showSuccess(L10n.text("successPlayerRemoved"))
        } catch {
            showError(error.localizedDescription)
        }
    }

    func transferAdministration(to memberId: String) async -> Bool {
        guard let teamId = selectedTeam?.id else { return false }

        isSubmitting = true
        defer { isSubmitting = false }

        do {
            try await teamService.updateMemberRole(teamId: teamId, memberId: memberId, role: .admin)
            await refreshSelectedTeamContent()
            showSuccess(L10n.text("successTeamUpdated"))
            return true
        } catch {
            showError(error.localizedDescription)
            return false
        }
    }

    func openCompositionEditor(for composition: TeamComposition?) {
        editingComposition = composition
        activeSheet = .compositionEditor(composition)
    }

    func presentInvitePlayerSheet() {
        activeSheet = .invitePlayer
    }

    func saveComposition(
        tabs: [CompositionTabDraft],
        deletedAlternativeIds: [String] = []
    ) async -> Bool {
        guard let teamId = selectedTeam?.id else { return false }
        guard let mainTab = tabs.first(where: \.isMain) ?? tabs.first else { return false }

        guard !mainTab.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            showError(L10n.text("compositionNameRequired"))
            return false
        }

        guard mainTab.starterAssignments.count == 7 else {
            showError(
                L10n.format(
                    "compositionMustHave7StartersCurrently",
                    mainTab.starterAssignments.count
                )
            )
            return false
        }

        isSubmitting = true
        defer { isSubmitting = false }

        let alternatives = tabs
            .filter { !$0.isMain }
            .map { tab in
                AlternativeCompositionRequest(
                    id: tab.serverAlternativeId,
                    name: tab.name,
                    formation: tab.formationKey,
                    tacticalNotes: tab.tacticalNotes.nilIfWhitespace,
                    starters: tab.starterAssignments.map {
                        CompositionSlotRequest(position: $0.key, memberId: $0.value)
                    },
                    substitutes: tab.substituteMemberIds.compactMap { memberId in
                        guard let memberId else { return nil }
                        return CompositionSlotRequest(position: "SUB", memberId: memberId)
                    }
                )
            }

        let request = CompositionSaveRequest(
            teamId: teamId,
            name: mainTab.name,
            formation: mainTab.formationKey,
            tacticalNotes: mainTab.tacticalNotes.nilIfWhitespace,
            starters: mainTab.starterAssignments.map {
                CompositionSlotRequest(position: $0.key, memberId: $0.value)
            },
            substitutes: mainTab.substituteMemberIds.compactMap { memberId in
                guard let memberId else { return nil }
                return CompositionSlotRequest(position: "SUB", memberId: memberId)
            },
            alternatives: alternatives.isEmpty ? nil : alternatives
        )

        do {
            if let compositionId = editingComposition?.id {
                for alternativeId in deletedAlternativeIds {
                    try await compositionService.deleteAlternativeFormation(
                        compositionId: compositionId,
                        alternativeId: alternativeId
                    )
                }
                _ = try await compositionService.updateComposition(id: compositionId, request: request)
                showSuccess(L10n.text("compositionModifiedSuccessfully"))
            } else {
                _ = try await compositionService.createComposition(request)
                showSuccess(L10n.text("compositionCreatedSuccessfully"))
            }
            await loadCompositions()
            compositionsLoadedForTeamId = selectedTeamId
            return true
        } catch {
            showError(error.localizedDescription)
            return false
        }
    }

    func deleteComposition(_ composition: TeamComposition) async -> Bool {
        do {
            try await compositionService.deleteComposition(id: composition.id)
            await loadCompositions()
            compositionsLoadedForTeamId = selectedTeamId
            showSuccess(L10n.text("compositionDeletedSuccessfully"))
            return true
        } catch {
            showError(error.localizedDescription)
            return false
        }
    }

    func onStatsSeasonChanged() async {
        await loadTeamStats()
        statsLoadedForTeamId = selectedTeamId
    }

    func onRankingSeasonChanged() async {
        await loadTeamRankings()
        rankingsLoadedForTeamId = selectedTeamId
    }

    func rankingEntries(for kind: TeamRankingKind) -> [RankingPlayerEntry] {
        guard let teamRankings else { return [] }
        switch kind {
        case .scorers:
            return teamRankings.scorers
        case .assisters:
            return teamRankings.assisters
        case .general:
            return teamRankings.general
        }
    }

    private func restoreSelection() {
        if let storedId = selectedTeamStore.selectedTeamId,
           teams.contains(where: { $0.id == storedId }) {
            selectedTeamId = storedId
            return
        }

        selectedTeamId = teams.first?.id ?? ""
    }

    private func refreshSelectedTeamContent() async {
        guard !selectedTeamId.isEmpty else {
            selectedTeam = nil
            compositions = []
            teamSeasonStats = nil
            teamRankings = nil
            teamInvitations = []
            clearSectionLoadErrors()
            return
        }

        isRefreshingTeam = true
        defer { isRefreshingTeam = false }

        if let cached = teams.first(where: { $0.id == selectedTeamId }) {
            selectedTeam = cached
            errorMessage = nil
        } else {
            do {
                selectedTeam = try await teamService.fetchTeam(id: selectedTeamId)
                if let index = teams.firstIndex(where: { $0.id == selectedTeamId }),
                   let selectedTeam {
                    teams[index] = selectedTeam
                }
                errorMessage = nil
            } catch {
                selectedTeam = nil
                errorMessage = error.localizedDescription
            }
        }

        clearSectionLoadErrors()
        await loadSeasonsForSelectedTeam()

        async let statsTask: Void = loadTeamStats()
        async let invitationsTask: Void = loadTeamInvitations()
        _ = await (statsTask, invitationsTask)
        statsLoadedForTeamId = selectedTeamId

        if rankingsLoadedForTeamId != selectedTeamId {
            teamRankings = nil
        }
        if compositionsLoadedForTeamId != selectedTeamId {
            compositions = []
        }
    }

    private func clearSectionLoadErrors() {
        compositionsLoadError = nil
        invitationsLoadError = nil
        statsLoadError = nil
        rankingsLoadError = nil
    }

    private func loadSeasonsForSelectedTeam() async {
        guard !selectedTeamId.isEmpty else {
            availableSeasons = []
            seasonsTeamId = nil
            return
        }

        guard seasonsTeamId != selectedTeamId else { return }

        let seasons = await statsService.fetchAvailableSeasons()
        if seasons.isEmpty {
            availableSeasons = [SeasonFormatter.currentSeason()]
        } else {
            availableSeasons = seasons
        }
        selectedStatsSeason = availableSeasons.first ?? ""
        selectedRankingSeason = availableSeasons.first ?? ""
        seasonsTeamId = selectedTeamId
    }

    private func loadCompositions() async {
        guard !selectedTeamId.isEmpty else {
            compositions = []
            compositionsLoadError = nil
            return
        }

        do {
            compositions = try await compositionService.fetchTeamCompositions(teamId: selectedTeamId)
            compositionsLoadError = nil
        } catch {
            compositions = []
            compositionsLoadError = error.localizedDescription
        }
    }

    private func loadTeamStats() async {
        guard !selectedTeamId.isEmpty, !selectedStatsSeason.isEmpty else {
            teamSeasonStats = nil
            statsLoadError = nil
            return
        }

        isLoadingStats = true
        defer { isLoadingStats = false }

        do {
            teamSeasonStats = try await statsService.fetchTeamSeasonStats(
                teamId: selectedTeamId,
                season: selectedStatsSeason
            )
            statsLoadError = nil
        } catch {
            teamSeasonStats = nil
            statsLoadError = error.localizedDescription
        }
    }

    private func loadTeamRankings() async {
        guard !selectedTeamId.isEmpty, !selectedRankingSeason.isEmpty else {
            teamRankings = nil
            rankingsLoadError = nil
            return
        }

        isLoadingRankings = true
        defer { isLoadingRankings = false }

        do {
            teamRankings = try await statsService.fetchTeamSeasonRankings(
                teamId: selectedTeamId,
                season: selectedRankingSeason
            )
            rankingsLoadError = nil
        } catch {
            teamRankings = nil
            rankingsLoadError = error.localizedDescription
        }
    }

    private func loadTeamInvitations() async {
        guard canManageTeam, !selectedTeamId.isEmpty else {
            teamInvitations = []
            invitationsLoadError = nil
            return
        }

        isLoadingInvitations = true
        defer { isLoadingInvitations = false }

        do {
            teamInvitations = try await teamService.fetchTeamInvitations(teamId: selectedTeamId)
            invitationsLoadError = nil
        } catch {
            teamInvitations = []
            invitationsLoadError = error.localizedDescription
        }
    }

    private func replaceTeam(_ team: SquadTeam) {
        if let index = teams.firstIndex(where: { $0.id == team.id }) {
            teams[index] = team
        }
        if selectedTeamId == team.id {
            selectedTeam = team
        }
    }

#if DEBUG
    static func preview(
        role: TeamRole = .admin,
        includeSecondTeam: Bool = true
    ) -> TeamViewModel {
        let viewModel = TeamViewModel()
        let selectedTeam = TeamPreviewData.team(role: role)
        viewModel.applyPreviewState(
            teams: TeamPreviewData.teams(includeSecond: includeSecondTeam),
            selectedTeam: selectedTeam,
            compositions: TeamPreviewData.compositions,
            stats: TeamPreviewData.stats,
            rankings: TeamPreviewData.rankings,
            invitations: TeamPreviewData.invitations,
            seasons: TeamPreviewData.seasons
        )
        return viewModel
    }

    static func previewEmpty() -> TeamViewModel {
        let viewModel = TeamViewModel()
        viewModel.applyPreviewState(
            teams: [],
            selectedTeam: nil,
            compositions: [],
            stats: nil,
            rankings: nil,
            invitations: [],
            seasons: []
        )
        return viewModel
    }

    private func applyPreviewState(
        teams: [SquadTeam],
        selectedTeam: SquadTeam?,
        compositions: [TeamComposition] = [],
        stats: TeamSeasonStatsPayload? = nil,
        rankings: TeamSeasonRankings? = nil,
        invitations: [TeamInvitation] = [],
        seasons: [String] = []
    ) {
        self.teams = teams
        self.selectedTeam = selectedTeam
        selectedTeamId = selectedTeam?.id ?? ""
        self.compositions = compositions
        teamSeasonStats = stats
        teamRankings = rankings
        teamInvitations = invitations
        availableSeasons = seasons
        selectedStatsSeason = seasons.first ?? TeamPreviewData.season
        selectedRankingSeason = seasons.first ?? TeamPreviewData.season
        isLoading = false
        isRefreshingTeam = false
        isLoadingStats = false
        isLoadingRankings = false
        isLoadingInvitations = false
        isSubmitting = false
    }
#endif
}

private extension String {
    var nilIfWhitespace: String? {
        let trimmed = trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }
}
