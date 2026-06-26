//
//  JoinTeamViewModel.swift
//  LeVestaire
//

import Combine
import Foundation
import SwiftUI

@MainActor
final class JoinTeamViewModel: ObservableObject {
    @Published var searchQuery = ""
    @Published var searchResults: [TeamSearchResult] = []
    @Published var myJoinRequests: [TeamJoinRequest] = []
    @Published var requestMessages: [String: String] = [:]
    @Published var isSearching = false
    @Published var isLoadingMyRequests = false
    @Published var submittingTeamIds: Set<String> = []
    @Published var cancellingRequestIds: Set<String> = []
    @Published var errorMessage: String?
    @Published var successMessage: String?

    private let teamService: TeamService

    var refreshTeams: (() async -> Void)?

    static let messageMaxLength = 500

    init(teamService: TeamService) {
        self.teamService = teamService
    }

    convenience init() {
        self.init(teamService: TeamService.shared)
    }

    var pendingJoinRequests: [TeamJoinRequest] {
        myJoinRequests.filter { $0.status == .pending }
    }

    func loadMyRequests() async {
        isLoadingMyRequests = true
        defer { isLoadingMyRequests = false }

        do {
            myJoinRequests = try await teamService.fetchMyJoinRequests()
        } catch {
            myJoinRequests = []
        }
    }

    func search() async {
        let query = searchQuery.resolvedTeamSearchQuery
        guard !query.isEmpty else {
            errorMessage = L10n.text("joinTeamSearchRequired")
            searchResults = []
            return
        }

        errorMessage = nil
        successMessage = nil
        isSearching = true
        defer { isSearching = false }

        do {
            searchResults = try await teamService.searchTeams(query: query)

            if searchResults.isEmpty {
                errorMessage = L10n.text("joinTeamSearchNoResults")
            }
        } catch let error as TeamServiceError {
            searchResults = []
            errorMessage = error.errorDescription
        } catch {
            searchResults = []
            errorMessage = error.localizedDescription
        }
    }

    func submitJoinRequest(for team: TeamSearchResult) async -> Bool {
        guard !team.isMember, !team.hasPendingJoinRequest else { return false }
        guard !submittingTeamIds.contains(team.id) else { return false }

        let message = requestMessages[team.id]?.trimmingCharacters(in: .whitespacesAndNewlines)
        if let message, message.count > Self.messageMaxLength {
            errorMessage = L10n.format("joinRequestMessageTooLong", Self.messageMaxLength)
            return false
        }

        submittingTeamIds.insert(team.id)
        defer { submittingTeamIds.remove(team.id) }

        do {
            _ = try await teamService.createJoinRequest(
                teamId: team.id,
                message: message?.isEmpty == true ? nil : message
            )
            successMessage = L10n.format("joinRequestSent", team.name)
            await refreshAfterMutation(teamId: team.id)
            return true
        } catch let error as TeamServiceError {
            errorMessage = error.errorDescription
            return false
        } catch {
            errorMessage = error.localizedDescription
        }
        return false
    }

    func cancelJoinRequest(_ request: TeamJoinRequest) async {
        guard request.status == .pending,
              !cancellingRequestIds.contains(request.id) else { return }

        cancellingRequestIds.insert(request.id)
        defer { cancellingRequestIds.remove(request.id) }

        do {
            try await teamService.cancelJoinRequest(teamId: request.teamId, requestId: request.id)
            successMessage = L10n.text("joinRequestCancelled")
            await refreshAfterMutation(teamId: request.teamId)
        } catch let error as TeamServiceError {
            errorMessage = error.errorDescription
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func messageBinding(for teamId: String) -> Binding<String> {
        Binding(
            get: { self.requestMessages[teamId, default: ""] },
            set: { self.requestMessages[teamId] = String($0.prefix(Self.messageMaxLength)) }
        )
    }

    func isSubmitting(teamId: String) -> Bool {
        submittingTeamIds.contains(teamId)
    }

    func isCancelling(requestId: String) -> Bool {
        cancellingRequestIds.contains(requestId)
    }

    private func refreshAfterMutation(teamId: String) async {
        await loadMyRequests()
        await refreshTeams?()

        if !searchQuery.resolvedTeamSearchQuery.isEmpty {
            await search()
        } else {
            searchResults = searchResults.map { result in
                guard result.id == teamId else { return result }
                let pending = myJoinRequests.contains { $0.teamId == teamId && $0.status == .pending }
                return TeamSearchResult(
                    id: result.id,
                    name: result.name,
                    memberCount: result.memberCount,
                    createdAt: result.createdAt,
                    sport: result.sport,
                    league: result.league,
                    logoUrl: result.logoUrl,
                    isMember: result.isMember,
                    hasPendingJoinRequest: pending
                )
            }
        }
    }
}

#if DEBUG
import SwiftUI
#endif
