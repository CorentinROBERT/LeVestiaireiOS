//
//  TeamJoinRequestsViewModel.swift
//  LeVestaire
//

import Combine
import Foundation

@MainActor
final class TeamJoinRequestsViewModel: ObservableObject {
    @Published var joinRequests: [TeamJoinRequest] = []
    @Published var isLoading = false
    @Published var loadError: String?
    @Published var reviewingRequestIds: Set<String> = []

    private weak var host: TeamViewModel?
    private let teamService: TeamService

    init(teamService: TeamService) {
        self.teamService = teamService
    }

    func attach(to host: TeamViewModel) {
        self.host = host
    }

    var pendingCount: Int {
        joinRequests.filter { $0.status == .pending }.count
    }

    func resetCache() {
        joinRequests = []
        loadError = nil
    }

    func loadIfNeeded() async {
        guard host?.canManageTeam == true,
              let teamId = host?.selectedTeamId,
              !teamId.isEmpty else {
            joinRequests = []
            loadError = nil
            return
        }

        isLoading = true
        defer { isLoading = false }

        do {
            joinRequests = try await teamService.fetchTeamJoinRequests(teamId: teamId, status: .pending)
            loadError = nil
        } catch {
            joinRequests = []
            loadError = error.localizedDescription
        }
    }

    func retry() async {
        await loadIfNeeded()
    }

    func reviewRequest(_ request: TeamJoinRequest, action: TeamJoinRequestReviewAction) async {
        guard request.status == .pending,
              !reviewingRequestIds.contains(request.id) else { return }

        reviewingRequestIds.insert(request.id)
        defer { reviewingRequestIds.remove(request.id) }

        do {
            try await teamService.reviewJoinRequest(
                teamId: request.teamId,
                requestId: request.id,
                action: action
            )
            await loadIfNeeded()
            await host?.refreshSelectedTeamContent()
            if action == .approve {
                await host?.loadInitialData()
            }
            host?.showSuccess(
                action == .approve
                    ? L10n.text("joinRequestApproved")
                    : L10n.text("joinRequestRejected")
            )
        } catch {
            host?.showError(error.localizedDescription)
        }
    }

    func isReviewing(_ requestId: String) -> Bool {
        reviewingRequestIds.contains(requestId)
    }

    func clearLoadErrors() {
        loadError = nil
    }
}
