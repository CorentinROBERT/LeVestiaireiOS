//
//  TeamInviteCoordinator.swift
//  LeVestaire
//

import Combine
import Foundation

@MainActor
final class TeamInviteCoordinator: ObservableObject {
    static let shared = TeamInviteCoordinator()

    @Published private(set) var pendingInviteTeamName: String?
    @Published private(set) var isValidatingPendingCode = false
    @Published private(set) var isJoiningTeam = false
    @Published var joinFeedbackMessage: String?
    @Published private(set) var joinedTeamId: String?

    private let codeStore: TeamInviteCodeStore
    private let teamService: TeamService
    private let authService: AuthService
    private let selectedTeamStore: SelectedTeamStore

    var hasPendingCode: Bool {
        codeStore.pendingCode != nil
    }

    var pendingCode: String? {
        codeStore.pendingCode
    }

    init(
        codeStore: TeamInviteCodeStore,
        teamService: TeamService,
        authService: AuthService,
        selectedTeamStore: SelectedTeamStore
    ) {
        self.codeStore = codeStore
        self.teamService = teamService
        self.authService = authService
        self.selectedTeamStore = selectedTeamStore
    }

    convenience init() {
        self.init(
            codeStore: .shared,
            teamService: .shared,
            authService: .shared,
            selectedTeamStore: .shared
        )
    }

    func handleIncomingURL(_ url: URL) {
        guard let code = DeepLinkParser.teamInviteCode(from: url) else { return }

        codeStore.save(code)
        joinedTeamId = nil
        joinFeedbackMessage = nil

        Task {
            await validatePendingCode()

            if authService.isAuthenticated {
                _ = await joinPendingTeamIfNeeded()
            }
        }
    }

    func validatePendingCode() async {
        guard let code = codeStore.pendingCode else {
            pendingInviteTeamName = nil
            return
        }

        isValidatingPendingCode = true
        defer { isValidatingPendingCode = false }

        do {
            let validation = try await teamService.validateTeamInviteCode(code)
            if validation.isValid == true {
                pendingInviteTeamName = validation.teamName
            } else {
                pendingInviteTeamName = nil
                joinFeedbackMessage = inviteErrorMessage(for: validation.reason)
            }
        } catch {
            pendingInviteTeamName = nil
        }
    }

    @discardableResult
    func joinPendingTeamIfNeeded() async -> SquadTeam? {
        guard authService.isAuthenticated, let code = codeStore.pendingCode else {
            return nil
        }

        guard !isJoiningTeam else { return nil }

        isJoiningTeam = true
        defer { isJoiningTeam = false }

        do {
            let team = try await teamService.joinTeam(inviteCode: code)
            codeStore.clear()
            pendingInviteTeamName = nil
            selectedTeamStore.selectedTeamId = team.id
            joinedTeamId = team.id
            joinFeedbackMessage = L10n.format("teamInviteJoinSuccess", team.name)
            return team
        } catch let error as TeamServiceError {
            joinFeedbackMessage = error.errorDescription
            return nil
        } catch {
            joinFeedbackMessage = error.localizedDescription
            return nil
        }
    }

    func clearPendingInvite() {
        codeStore.clear()
        pendingInviteTeamName = nil
    }

    func consumeJoinedTeamId() -> String? {
        defer { joinedTeamId = nil }
        return joinedTeamId
    }

    private func inviteErrorMessage(for reason: String?) -> String {
        switch reason?.lowercased() {
        case "expired":
            return L10n.text("teamInviteCodeExpired")
        case "revoked", "not_found":
            return L10n.text("teamInviteCodeInvalid")
        default:
            return L10n.text("teamInviteCodeInvalid")
        }
    }
}
