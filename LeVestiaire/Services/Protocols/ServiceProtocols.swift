//
//  ServiceProtocols.swift
//  LeVestaire
//

import Combine
import Foundation
import UIKit

@MainActor
protocol AuthServicing: AnyObject, ObservableObject {
    var isAuthenticated: Bool { get }
    var requiresPasswordReauthentication: Bool { get }
    var currentUser: User? { get }

    func login(email: String, password: String) async -> LoginResponse
    func register(
        email: String,
        password: String,
        firstName: String,
        lastName: String,
        birthDate: Date?,
        language: String?,
        teamInviteCode: String?
    ) async -> LoginResponse
    func requestPasswordReset(email: String) async -> PasswordResetResponse
    func checkEmailVerification(email: String) async -> EmailVerificationResponse
    func resendVerificationEmail(email: String) async -> LoginResponse
    func confirmPasswordReset(token: String, newPassword: String) async -> PasswordResetResponse
    func markSportProfileCompleted()
    func fetchCurrentUser(retryOnUnauthorized: Bool) async -> User?
    func logout() async
}

@MainActor
protocol AuthUserObserving: AnyObject {
    var currentUserPublisher: AnyPublisher<User?, Never> { get }
}

extension AuthService: AuthUserObserving {
    var currentUserPublisher: AnyPublisher<User?, Never> {
        $currentUser.eraseToAnyPublisher()
    }
}

@MainActor
protocol TeamMembershipServicing: AnyObject {
    func fetchUserTeams() async throws -> [SquadTeam]
}

@MainActor
protocol MatchListingServicing: AnyObject {
    func fetchMatches(criteria: MatchFetchCriteria) async throws -> MatchListResponse
    func fetchMatch(id: String, authenticated: Bool) async throws -> MatchDetail
    func updateMyAvailability(matchId: String, status: MatchAvailabilityStatus) async throws -> MyAvailabilityResponse
    func createMatch(request: CreateMatchRequest) async throws -> MatchDetail
}

extension MatchListingServicing {
    func fetchMatch(id: String) async throws -> MatchDetail {
        try await fetchMatch(id: id, authenticated: true)
    }
}

@MainActor
protocol MatchDetailServicing: MatchListingServicing {
    func fetchMyAvailability(matchId: String) async throws -> MyAvailabilityResponse
    func forcePlayerAvailability(
        matchId: String,
        playerId: String,
        status: MatchAvailabilityStatus
    ) async throws -> MatchAvailabilityEntry
    func fetchAvailabilityPresent(matchId: String) async throws -> [MatchPresentMember]
    func fetchAvailabilityRoster(matchId: String) async throws -> MatchAvailabilityRoster
    func fetchSelectablePlayers(matchId: String) async throws -> [MatchSelectablePlayer]
    func fetchEvents(matchId: String) async throws -> [MatchEvent]
    func createEvent(matchId: String, request: CreateMatchEventRequest) async throws -> MatchEvent
    func deleteEvent(matchId: String, eventId: String) async throws
    func fetchMatchStats(matchId: String) async throws -> MatchStatsPayload
    func createMatchComposition(matchId: String, request: MatchCompositionSaveRequest) async throws -> MatchDetail
    func updateMatchComposition(matchId: String, request: MatchCompositionSaveRequest) async throws -> MatchDetail
    func updateMatchCompositionCaptain(matchId: String, captainId: String?) async throws -> MatchDetail
    func lockMatchComposition(matchId: String) async throws -> MatchDetail
    func publishMatch(id: String) async throws -> MatchDetail
    func updateMatchStatus(id: String, status: MatchStatus) async throws -> MatchDetail
    func updateScore(matchId: String, scoreHome: Int, scoreAway: Int) async throws -> MatchDetail
    func updateMatch(id: String, request: UpdateMatchRequest) async throws -> MatchDetail
}

@MainActor
protocol TeamDetailServicing: TeamMembershipServicing {
    func fetchTeam(id: String) async throws -> SquadTeam
    func fetchTeamGuests(teamId: String) async throws -> [TeamGuest]
}

@MainActor
protocol QuizServicing: AnyObject {
    func fetchQuizzesForMatch(matchId: String) async throws -> [MatchQuizSummary]
    func fetchQuiz(id: String) async throws -> MatchQuizDetail
    func createQuiz(matchId: String) async throws -> MatchQuizDetail
    func updateQuiz(id: String, request: MatchQuizPatchRequest) async throws -> MatchQuizDetail
    func deleteQuiz(id: String) async throws
    func submitQuiz(id: String, request: MatchQuizSubmitRequest) async throws -> MatchQuizSubmitResult
    func fetchUserSubmission(quizId: String) async throws -> MatchQuizUserSubmission?
    func fetchLeaderboard(quizId: String) async throws -> MatchQuizLeaderboardResponse
}

@MainActor
protocol CompositionServicing: AnyObject {
    func fetchTeamCompositions(teamId: String) async throws -> [TeamComposition]
    func createComposition(_ request: CompositionSaveRequest) async throws -> TeamComposition
    func updateComposition(id: String, request: CompositionSaveRequest) async throws -> TeamComposition
    func updateCompositionCaptain(id: String, captainId: String?) async throws -> TeamComposition
    func deleteComposition(id: String) async throws
    func deleteAlternativeFormation(compositionId: String, alternativeId: String) async throws
}

@MainActor
protocol TeamManagementServicing: AnyObject {
    func fetchTeamJoinRequests(
        teamId: String,
        status: TeamJoinRequestStatus?
    ) async throws -> [TeamJoinRequest]
    func reviewJoinRequest(
        teamId: String,
        requestId: String,
        action: TeamJoinRequestReviewAction
    ) async throws
    func fetchTeamInvitations(teamId: String) async throws -> [TeamInvitation]
    func invitePlayer(teamId: String, email: String, firstName: String?, lastName: String?) async throws
    func resendInvitation(invitationId: String) async throws
    func cancelInvitation(invitationId: String) async throws
    func addGuest(teamId: String, request: CreateGuestRequest) async throws
    func deleteGuest(guestId: String) async throws
    func mergeGuest(guestId: String, userId: String) async throws
    func updateMemberRole(teamId: String, memberId: String, role: TeamRole) async throws -> SquadTeam
    func removeMember(teamId: String, memberId: String) async throws
}

@MainActor
protocol StatsServicing: AnyObject {
    func fetchAvailableSeasons() async -> [String]
    func fetchTeamSeasonStats(teamId: String, season: String) async throws -> TeamSeasonStatsPayload?
    func fetchTeamSeasonRankings(teamId: String, season: String) async throws -> TeamSeasonRankings?
    func fetchTeamSeasonInsights(teamId: String, season: String) async throws -> TeamSeasonInsightsPayload?
    func fetchTeamSeasonDuos(
        teamId: String,
        season: String,
        limit: Int
    ) async throws -> TeamSeasonDuosPayload?
}

extension StatsServicing {
    func fetchTeamSeasonDuos(teamId: String, season: String) async throws -> TeamSeasonDuosPayload? {
        try await fetchTeamSeasonDuos(teamId: teamId, season: season, limit: 3)
    }
}

@MainActor
protocol ProfileStatsServicing: StatsServicing {
    func fetchUserSeasonStats(userId: String, season: String) async -> UserSeasonStats?
}

@MainActor
protocol TeamJoinServicing: AnyObject {
    func searchTeams(query: String) async throws -> [TeamSearchResult]
    func createJoinRequest(teamId: String, message: String?) async throws -> TeamJoinRequest
    func cancelJoinRequest(teamId: String, requestId: String) async throws
    func fetchMyJoinRequests() async throws -> [TeamJoinRequest]
}

@MainActor
protocol TeamHostServicing: TeamDetailServicing, TeamManagementServicing, TeamJoinServicing {
    func fetchMyTeams() async throws -> MyTeamsResponse
    func createTeam(name: String, description: String?, logo: UIImage?) async throws -> SquadTeam
    func updateTeam(
        id: String,
        name: String?,
        description: String?,
        logo: UIImage?
    ) async throws -> SquadTeam
    func deleteTeam(id: String) async throws
    func leaveTeam(id: String) async throws
    func fetchTeamInviteLink(teamId: String) async throws -> TeamInviteLink
    func regenerateTeamInviteLink(teamId: String) async throws -> TeamInviteLink
}

@MainActor
protocol TeamInviteCoordinating: AnyObject, ObservableObject {
    var pendingInviteTeamName: String? { get }
    var pendingCode: String? { get }
    func joinPendingTeamIfNeeded() async -> SquadTeam?
}

protocol PendingAuthCredentialsStoring: AnyObject {
    func save(email: String, password: String)
    func load() -> (email: String, password: String)?
    func clear()
}

protocol SavedLoginEmailStoring: AnyObject {
    func load() -> String?
    func save(_ email: String)
    func clear()
}

@MainActor
protocol BiometricAuthStoring: AnyObject {
    var lastErrorMessage: String? { get }
}

@MainActor
protocol SportProfileServicing: AnyObject {
    func fetchProfile() async -> SportProfileResponse
    func saveProfile(_ request: SportProfileRequest) async -> SportProfileResponse
    func uploadProfilePicture(_ image: UIImage) async -> ProfilePictureResponse
}

protocol ReferenceDataServicing: AnyObject {
    func leagues() -> [LeagueReference]
    func teams(forLeague leagueKey: String) -> [String]
}

@MainActor
protocol AccountServicing: AnyObject {
    func requestAccountDeletion() async -> AccountActionResponse
    func cancelAccountDeletion() async -> AccountActionResponse
}

protocol OnboardingStoring: AnyObject {
    var hasCompletedOnboarding: Bool { get }
    func markOnboardingCompleted()
}

@MainActor
protocol NotificationServicing: AnyObject {
    func fetchNotifications(criteria: NotificationFetchCriteria) async throws -> NotificationListResponse
    func fetchUnreadCount() async throws -> Int
    func markAsRead(notificationId: String) async throws
    func markAllAsRead() async throws
    func archive(notificationId: String) async throws
    func unarchive(notificationId: String) async throws
}

protocol RemoteContentFetching {
    func data(from url: URL) async throws -> (Data, URLResponse)
}

final class SharedRemoteContentFetcher: RemoteContentFetching {
    func data(from url: URL) async throws -> (Data, URLResponse) {
        try await URLSession.shared.data(from: url)
    }
}

protocol APIConfiguring: AnyObject {
    var environment: APIEnvironment { get set }
    var customBaseURL: String { get set }
    var resolvedBaseURL: String { get }
    var healthCheckURL: String? { get }
}

@MainActor
protocol PushNotificationTesting: AnyObject {
    func sendTestPushNotification(allowProduction: Bool) async throws
}

@MainActor
final class ObservableAuthServiceBox: ObservableObject {
    let service: any AuthServicing
    private var cancellable: AnyCancellable?

    init(_ service: some AuthServicing) {
        self.service = service
        cancellable = service.objectWillChange
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.objectWillChange.send()
            }
    }
}

extension AuthService: AuthServicing {}
extension MatchService: MatchDetailServicing {}
extension QuizService: QuizServicing {}
extension CompositionService: CompositionServicing {}
extension StatsService: ProfileStatsServicing {}
extension TeamService: TeamHostServicing {}
extension TeamInviteCoordinator: TeamInviteCoordinating {}
extension PendingAuthCredentialsStore: PendingAuthCredentialsStoring {}
extension SavedLoginEmailStore: SavedLoginEmailStoring {}
extension BiometricAuthStore: BiometricAuthStoring {}
extension SportProfileService: SportProfileServicing {}
extension ReferenceDataService: ReferenceDataServicing {}
extension AccountService: AccountServicing {}
extension OnboardingStore: OnboardingStoring {}
extension NotificationService: NotificationServicing {}
extension APIConfiguration: APIConfiguring {}
extension PushNotificationManager: PushNotificationTesting {}
