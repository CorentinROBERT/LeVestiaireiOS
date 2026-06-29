//
//  ViewModelMocks.swift
//  LeVestiaireTests
//

import Combine
import Foundation
import UIKit
@testable import LeVestiaire

@MainActor
final class MockAuthService: ObservableObject, AuthServicing {
  @Published var isAuthenticated = false
  @Published var requiresPasswordReauthentication = false
  @Published var currentUser: User?

  var loginHandler: ((String, String) async -> LoginResponse)?
  var registerHandler: ((
    String, String, String, String, Date?, String?, String?
  ) async -> LoginResponse)?
  var requestPasswordResetHandler: ((String) async -> PasswordResetResponse)?
  var checkEmailVerificationHandler: ((String) async -> EmailVerificationResponse)?
  var resendVerificationEmailHandler: ((String) async -> LoginResponse)?
  var confirmPasswordResetHandler: ((String, String) async -> PasswordResetResponse)?

  var markSportProfileCompletedCallCount = 0
  var fetchCurrentUserHandler: ((Bool) async -> User?)?
  var logoutCallCount = 0

  var loginCallCount = 0
  var registerCallCount = 0
  var lastLoginEmail: String?
  var lastRegisterInviteCode: String?

  func login(email: String, password: String) async -> LoginResponse {
    loginCallCount += 1
    lastLoginEmail = email
    if let loginHandler {
      return await loginHandler(email, password)
    }
    return LoginResponse(success: false)
  }

  func register(
    email: String,
    password: String,
    firstName: String,
    lastName: String,
    birthDate: Date?,
    language: String?,
    teamInviteCode: String?
  ) async -> LoginResponse {
    registerCallCount += 1
    lastRegisterInviteCode = teamInviteCode
    if let registerHandler {
      return await registerHandler(
        email,
        password,
        firstName,
        lastName,
        birthDate,
        language,
        teamInviteCode
      )
    }
    return LoginResponse(success: false)
  }

  func requestPasswordReset(email: String) async -> PasswordResetResponse {
    if let requestPasswordResetHandler {
      return await requestPasswordResetHandler(email)
    }
    return PasswordResetResponse(success: false)
  }

  func checkEmailVerification(email: String) async -> EmailVerificationResponse {
    if let checkEmailVerificationHandler {
      return await checkEmailVerificationHandler(email)
    }
    return EmailVerificationResponse(success: false)
  }

  func resendVerificationEmail(email: String) async -> LoginResponse {
    if let resendVerificationEmailHandler {
      return await resendVerificationEmailHandler(email)
    }
    return LoginResponse(success: false)
  }

  func confirmPasswordReset(token: String, newPassword: String) async -> PasswordResetResponse {
    if let confirmPasswordResetHandler {
      return await confirmPasswordResetHandler(token, newPassword)
    }
    return PasswordResetResponse(success: false)
  }

  func markSportProfileCompleted() {
    markSportProfileCompletedCallCount += 1
  }

  func fetchCurrentUser(retryOnUnauthorized: Bool) async -> User? {
    if let fetchCurrentUserHandler {
      return await fetchCurrentUserHandler(retryOnUnauthorized)
    }
    return currentUser
  }

  func logout() async {
    logoutCallCount += 1
    isAuthenticated = false
    currentUser = nil
  }
}

extension MockAuthService: AuthUserObserving {
  var currentUserPublisher: AnyPublisher<User?, Never> {
    $currentUser.eraseToAnyPublisher()
  }
}

@MainActor
final class MockTeamJoinService: TeamHostServicing {
  var searchHandler: ((String) async throws -> [TeamSearchResult])?
  var createJoinRequestHandler: ((String, String?) async throws -> TeamJoinRequest)?
  var cancelJoinRequestHandler: ((String, String) async throws -> Void)?
  var fetchMyJoinRequestsHandler: (() async throws -> [TeamJoinRequest])?
  var fetchUserTeamsHandler: (() async throws -> [SquadTeam])?
  var fetchTeamHandler: ((String) async throws -> SquadTeam)?
  var fetchTeamGuestsHandler: ((String) async throws -> [TeamGuest])?

  var fetchMyTeamsHandler: (() async throws -> MyTeamsResponse)?
  var createTeamHandler: ((String, String?, UIImage?) async throws -> SquadTeam)?
  var updateTeamHandler: ((String, String?, String?, UIImage?) async throws -> SquadTeam)?
  var deleteTeamHandler: ((String) async throws -> Void)?
  var leaveTeamHandler: ((String) async throws -> Void)?
  var fetchTeamInviteLinkHandler: ((String) async throws -> TeamInviteLink)?
  var regenerateTeamInviteLinkHandler: ((String) async throws -> TeamInviteLink)?

  var fetchTeamJoinRequestsHandler: ((String, TeamJoinRequestStatus?) async throws -> [TeamJoinRequest])?
  var reviewJoinRequestHandler: ((String, String, TeamJoinRequestReviewAction) async throws -> Void)?
  var fetchTeamInvitationsHandler: ((String) async throws -> [TeamInvitation])?
  var invitePlayerHandler: ((String, String, String?, String?) async throws -> Void)?
  var resendInvitationHandler: ((String) async throws -> Void)?
  var cancelInvitationHandler: ((String) async throws -> Void)?
  var addGuestHandler: ((String, CreateGuestRequest) async throws -> Void)?
  var deleteGuestHandler: ((String) async throws -> Void)?
  var mergeGuestHandler: ((String, String) async throws -> Void)?
  var updateMemberRoleHandler: ((String, String, TeamRole) async throws -> SquadTeam)?
  var removeMemberHandler: ((String, String) async throws -> Void)?

  var lastInvitedEmail: String?
  var lastSearchQuery: String?
  var lastJoinRequestTeamId: String?

  func fetchUserTeams() async throws -> [SquadTeam] {
    if let fetchUserTeamsHandler {
      return try await fetchUserTeamsHandler()
    }
    return []
  }

  func fetchTeam(id: String) async throws -> SquadTeam {
    if let fetchTeamHandler {
      return try await fetchTeamHandler(id)
    }
    throw TeamServiceError.requestFailed("missing handler")
  }

  func fetchTeamGuests(teamId: String) async throws -> [TeamGuest] {
    if let fetchTeamGuestsHandler {
      return try await fetchTeamGuestsHandler(teamId)
    }
    return []
  }

  func searchTeams(query: String) async throws -> [TeamSearchResult] {
    lastSearchQuery = query
    if let searchHandler {
      return try await searchHandler(query)
    }
    return []
  }

  func createJoinRequest(teamId: String, message: String?) async throws -> TeamJoinRequest {
    lastJoinRequestTeamId = teamId
    if let createJoinRequestHandler {
      return try await createJoinRequestHandler(teamId, message)
    }
    throw TeamServiceError.requestFailed("missing handler")
  }

  func cancelJoinRequest(teamId: String, requestId: String) async throws {
    if let cancelJoinRequestHandler {
      try await cancelJoinRequestHandler(teamId, requestId)
      return
    }
    throw TeamServiceError.requestFailed("missing handler")
  }

  func fetchMyJoinRequests() async throws -> [TeamJoinRequest] {
    if let fetchMyJoinRequestsHandler {
      return try await fetchMyJoinRequestsHandler()
    }
    return []
  }

  func fetchMyTeams() async throws -> MyTeamsResponse {
    if let fetchMyTeamsHandler {
      return try await fetchMyTeamsHandler()
    }
    return try ViewModelTestFixtures.myTeamsResponse(teams: [])
  }

  func createTeam(name: String, description: String?, logo: UIImage?) async throws -> SquadTeam {
    if let createTeamHandler {
      return try await createTeamHandler(name, description, logo)
    }
    throw TeamServiceError.requestFailed("missing handler")
  }

  func updateTeam(
    id: String,
    name: String?,
    description: String?,
    logo: UIImage?
  ) async throws -> SquadTeam {
    if let updateTeamHandler {
      return try await updateTeamHandler(id, name, description, logo)
    }
    throw TeamServiceError.requestFailed("missing handler")
  }

  func deleteTeam(id: String) async throws {
    if let deleteTeamHandler {
      try await deleteTeamHandler(id)
      return
    }
    throw TeamServiceError.requestFailed("missing handler")
  }

  func leaveTeam(id: String) async throws {
    if let leaveTeamHandler {
      try await leaveTeamHandler(id)
      return
    }
    throw TeamServiceError.requestFailed("missing handler")
  }

  func fetchTeamInviteLink(teamId: String) async throws -> TeamInviteLink {
    if let fetchTeamInviteLinkHandler {
      return try await fetchTeamInviteLinkHandler(teamId)
    }
    throw TeamServiceError.requestFailed("missing handler")
  }

  func regenerateTeamInviteLink(teamId: String) async throws -> TeamInviteLink {
    if let regenerateTeamInviteLinkHandler {
      return try await regenerateTeamInviteLinkHandler(teamId)
    }
    throw TeamServiceError.requestFailed("missing handler")
  }

  func fetchTeamJoinRequests(
    teamId: String,
    status: TeamJoinRequestStatus?
  ) async throws -> [TeamJoinRequest] {
    if let fetchTeamJoinRequestsHandler {
      return try await fetchTeamJoinRequestsHandler(teamId, status)
    }
    return []
  }

  func reviewJoinRequest(
    teamId: String,
    requestId: String,
    action: TeamJoinRequestReviewAction
  ) async throws {
    if let reviewJoinRequestHandler {
      try await reviewJoinRequestHandler(teamId, requestId, action)
      return
    }
    throw TeamServiceError.requestFailed("missing handler")
  }

  func fetchTeamInvitations(teamId: String) async throws -> [TeamInvitation] {
    if let fetchTeamInvitationsHandler {
      return try await fetchTeamInvitationsHandler(teamId)
    }
    return []
  }

  func invitePlayer(
    teamId: String,
    email: String,
    firstName: String?,
    lastName: String?
  ) async throws {
    lastInvitedEmail = email
    if let invitePlayerHandler {
      try await invitePlayerHandler(teamId, email, firstName, lastName)
      return
    }
    throw TeamServiceError.requestFailed("missing handler")
  }

  func resendInvitation(invitationId: String) async throws {
    if let resendInvitationHandler {
      try await resendInvitationHandler(invitationId)
      return
    }
    throw TeamServiceError.requestFailed("missing handler")
  }

  func cancelInvitation(invitationId: String) async throws {
    if let cancelInvitationHandler {
      try await cancelInvitationHandler(invitationId)
      return
    }
    throw TeamServiceError.requestFailed("missing handler")
  }

  func addGuest(teamId: String, request: CreateGuestRequest) async throws {
    if let addGuestHandler {
      try await addGuestHandler(teamId, request)
      return
    }
    throw TeamServiceError.requestFailed("missing handler")
  }

  func deleteGuest(guestId: String) async throws {
    if let deleteGuestHandler {
      try await deleteGuestHandler(guestId)
      return
    }
    throw TeamServiceError.requestFailed("missing handler")
  }

  func mergeGuest(guestId: String, userId: String) async throws {
    if let mergeGuestHandler {
      try await mergeGuestHandler(guestId, userId)
      return
    }
    throw TeamServiceError.requestFailed("missing handler")
  }

  func updateMemberRole(
    teamId: String,
    memberId: String,
    role: TeamRole
  ) async throws -> SquadTeam {
    if let updateMemberRoleHandler {
      return try await updateMemberRoleHandler(teamId, memberId, role)
    }
    throw TeamServiceError.requestFailed("missing handler")
  }

  func removeMember(teamId: String, memberId: String) async throws {
    if let removeMemberHandler {
      try await removeMemberHandler(teamId, memberId)
      return
    }
    throw TeamServiceError.requestFailed("missing handler")
  }
}

typealias MockTeamHostService = MockTeamJoinService

@MainActor
final class MockTeamInviteCoordinator: ObservableObject, TeamInviteCoordinating {
  @Published var pendingInviteTeamName: String?
  var pendingCode: String?
  var joinPendingTeamIfNeededCallCount = 0
  var joinResult: SquadTeam?

  func joinPendingTeamIfNeeded() async -> SquadTeam? {
    joinPendingTeamIfNeededCallCount += 1
    return joinResult
  }
}

final class InMemoryPendingCredentialsStore: PendingAuthCredentialsStoring {
  private var credentials: (email: String, password: String)?

  func save(email: String, password: String) {
    credentials = (email, password)
  }

  func load() -> (email: String, password: String)? {
    credentials
  }

  func clear() {
    credentials = nil
  }
}

final class InMemorySavedLoginEmailStore: SavedLoginEmailStoring {
  private var email: String?

  func load() -> String? {
    email
  }

  func save(_ email: String) {
    self.email = email
  }

  func clear() {
    email = nil
  }
}

@MainActor
final class MockBiometricAuthStore: BiometricAuthStoring {
  var lastErrorMessage: String?
}

enum ViewModelTestFixtures {
  static let user = User(
    id: "user-1",
    email: "user@example.com",
    firstName: "Test",
    lastName: "User",
    emailVerified: true
  )

  static let loginSuccessResponse = LoginResponse(
    success: true,
    data: LoginData(
      user: user,
      token: "access-token",
      refreshToken: "refresh-token"
    )
  )

  static let team = SquadTeam(
    id: "team-1",
    name: "FC Test",
    memberCount: 12,
    currentUserRole: .player
  )

  static let searchResult = TeamSearchResult(
    id: "team-1",
    name: "FC Test",
    memberCount: 12
  )

  static let adminTeam = SquadTeam(
    id: "team-admin",
    name: "FC Admin",
    adminId: "user-1",
    memberCount: 8,
    currentUserRole: .admin,
    isActive: true
  )

  static let playerTeam = SquadTeam(
    id: "team-player",
    name: "FC Player",
    memberCount: 5,
    currentUserRole: .player,
    isActive: true
  )

  static var managedTeam: SquadTeam {
    let members = CompositionTestFixtures.sevenStarterMembers()
    return SquadTeam(
      id: "team-admin",
      name: "FC Admin",
      adminId: "user-1",
      members: members,
      memberCount: members.count,
      currentUserRole: .admin,
      isActive: true
    )
  }

  static func joinRequest(
    id: String = "request-1",
    teamId: String = "team-admin",
    status: TeamJoinRequestStatus = .pending
  ) -> TeamJoinRequest {
    TeamJoinRequest(
      id: id,
      teamId: teamId,
      firstName: "Jean",
      lastName: "Dupont",
      status: status
    )
  }

  static func teamInvitation(
    id: String = "invite-1",
    status: TeamInvitationStatus = .pending
  ) -> TeamInvitation {
    TeamInvitation(
      id: id,
      email: "invite@example.com",
      firstName: "Marie",
      lastName: "Martin",
      status: status
    )
  }

  static func teamSeasonStats(goals: Int = 12) -> TeamSeasonStatsPayload {
    TeamSeasonStatsPayload(
      teamId: "team-admin",
      season: "2025-2026",
      totals: TeamSeasonStatsTotals(goals: goals, assists: 8),
      players: [
        TeamPlayerSeasonStats(
          id: "user-1",
          firstName: "Alice",
          lastName: "Martin",
          goals: goals
        ),
      ]
    )
  }

  static func teamSeasonRankings() -> TeamSeasonRankings {
    TeamSeasonRankings(
      scorers: [RankingPlayerEntry(id: "user-1", firstName: "Alice", lastName: "Martin", goals: 5)],
      assisters: [],
      general: []
    )
  }

  static func userSeasonStats(goals: Int = 3) -> UserSeasonStats {
    UserSeasonStats(season: "2025-2026", matchesPlayed: 10, goals: goals, assists: 2)
  }

  static func sportProfileData(
    team: String = "PSG",
    league: String = "ligue-1"
  ) -> SportProfileData {
    SportProfileData(
      id: "profile-1",
      userId: "user-1",
      favoriteLeague: league,
      favoriteTeam: team,
      strongFoot: "right",
      experienceLevel: 1,
      favoritePositions: ["centerMidfielder"],
      playedPositions: ["centerMidfielder"],
      availabilities: ["monday"],
      isCompleted: true,
      jerseyNumber: 10
    )
  }

  static func myTeamsResponse(teams: [SquadTeam]) throws -> MyTeamsResponse {
    let teamPayload = teams.map { team in
      """
      {"id":"\(team.id)","name":"\(team.name)","memberCount":\(team.memberCount ?? 0)}
      """
    }.joined(separator: ",")
    let json = """
    {"success":true,"data":{"teams":[\(teamPayload)]}}
    """
    return try JSONDecoder().decode(MyTeamsResponse.self, from: Data(json.utf8))
  }

  static func teamInviteLink(
    teamId: String = "team-admin",
    code: String = "INVITE123"
  ) throws -> TeamInviteLink {
    let json = """
    {"teamId":"\(teamId)","code":"\(code)","shareUrl":"https://example.com/invite"}
    """
    return try JSONDecoder().decode(TeamInviteLink.self, from: Data(json.utf8))
  }

  static func notificationListResponse(
    notifications: [AppNotification] = [],
    page: Int = 1,
    hasNextPage: Bool = false
  ) throws -> NotificationListResponse {
    let items = notifications.map { notification in
      let createdAt = ISO8601DateFormatter().string(from: notification.createdAt)
      return """
      {"id":"\(notification.id)","title":"\(notification.title)","body":"\(notification.body)","type":"\(notification.type.rawValue)","isRead":\(notification.isRead),"isArchived":\(notification.isArchived),"createdAt":"\(createdAt)","channels":["in_app"]}
      """
    }.joined(separator: ",")
    let json = """
    {"success":true,"data":[\(items)],"pagination":{"page":\(page),"limit":20,"total":\(notifications.count),"totalPages":1,"hasNextPage":\(hasNextPage)}}
    """
    return try JSONDecoder().decode(NotificationListResponse.self, from: Data(json.utf8))
  }

  static func matchItem(
    id: String,
    status: MatchStatus = .upcoming,
    teamId: String = "team-1",
    homeTeamName: String = "FC Test",
    date: Date = Date()
  ) -> MatchItem {
    MatchItem(
      id: id,
      title: "vs Opponent",
      status: status,
      capabilities: MatchCapabilities(
        canRespond: true,
        canManageAvailability: false,
        canManageComposition: false,
        canPublish: false,
        canStartMatch: false,
        canManageEvents: false,
        canUpdateScore: false,
        canFinishMatch: false
      ),
      opponentTeam: "Opponent",
      location: "Stade",
      homeTeamName: homeTeamName,
      teamId: teamId,
      date: date
    )
  }

  static func matchDetail(
    id: String,
    status: MatchStatus = .upcoming,
    teamId: String = "team-1",
    homeTeamName: String = "FC Test",
    myAvailabilityStatus: MatchAvailabilityStatus? = .available,
    capabilities: MatchCapabilities? = nil,
    composition: TeamComposition? = nil,
    isCompositionLocked: Bool = false,
    date: Date = Date()
  ) -> MatchDetail {
    let resolvedCapabilities = capabilities ?? MatchCapabilities(
      canRespond: true,
      canManageAvailability: false,
      canManageComposition: false,
      canPublish: false,
      canStartMatch: false,
      canManageEvents: false,
      canUpdateScore: false,
      canFinishMatch: false
    )
    return MatchDetail(
      id: id,
      title: "vs Opponent",
      status: status,
      statusLabel: nil,
      preparationPhase: nil,
      isPreparationLocked: false,
      isCompositionLocked: isCompositionLocked,
      canPublish: false,
      publishBlockers: [],
      myAvailabilityStatus: myAvailabilityStatus,
      availabilitySummary: nil,
      capabilities: resolvedCapabilities,
      opponentTeam: "Opponent",
      location: "Stade",
      homeTeamName: homeTeamName,
      teamId: teamId,
      date: date,
      startTime: "20:00",
      homeScore: nil,
      awayScore: nil,
      composition: composition
    )
  }

  static func quizQuestions(count: Int = 10, includesFalseAnswer: Bool = true) -> [MatchQuizQuestion] {
    guard count > 0 else { return [] }
    var questions = (0..<max(0, count - (includesFalseAnswer ? 1 : 0))).map { index in
      MatchQuizQuestion(text: "Question \(index)", correctAnswer: true, source: "custom")
    }
    if includesFalseAnswer {
      questions.append(MatchQuizQuestion(text: "False question", correctAnswer: false, source: "custom"))
    }
    return questions
  }

  static func decodeMatchEvent(id: String, type: String) throws -> MatchEvent {
    let data = Data("{\"id\":\"\(id)\",\"type\":\"\(type)\",\"isActive\":true}".utf8)
    return try JSONDecoder().decode(MatchEvent.self, from: data)
  }

  static func matchStats(
    matchId: String = "match-1",
    goals: Int = 2
  ) -> MatchStatsPayload {
    MatchStatsPayload(
      matchId: matchId,
      totals: nil,
      players: [
        TeamPlayerSeasonStats(
          id: "user-1",
          firstName: "Alice",
          lastName: "Martin",
          goals: goals
        ),
      ]
    )
  }

  static func quizDetail(
    id: String = "quiz-1",
    questions: [MatchQuizQuestion]? = nil
  ) -> MatchQuizDetail {
    MatchQuizDetail(
      id: id,
      title: "Quiz test",
      status: "open",
      questions: questions ?? quizQuestions()
    )
  }

  static func quizSubmitResult(
    isComplete: Bool = false,
    attemptCount: Int = 1,
    falseFound: Int = 0,
    falseAnswersCount: Int = 1
  ) throws -> MatchQuizSubmitResult {
    let json = """
    {"isComplete":\(isComplete),"attemptCount":\(attemptCount),"falseFound":\(falseFound),"falseAnswersCount":\(falseAnswersCount)}
    """
    return try JSONDecoder().decode(MatchQuizSubmitResult.self, from: Data(json.utf8))
  }

  static func quizUserSubmission(
    attemptCount: Int = 1,
    isComplete: Bool = false,
    answers: [(questionId: String, answer: Bool)] = []
  ) throws -> MatchQuizUserSubmission {
    let answersJSON = answers.map {
      "{\"questionId\":\"\($0.questionId)\",\"answer\":\($0.answer.description)}"
    }.joined(separator: ",")
    let payload = answers.isEmpty
      ? "{\"attemptCount\":\(attemptCount),\"isComplete\":\(isComplete)}"
      : "{\"attemptCount\":\(attemptCount),\"isComplete\":\(isComplete),\"answers\":[\(answersJSON)]}"
    return try JSONDecoder().decode(MatchQuizUserSubmission.self, from: Data(payload.utf8))
  }

  static func manageCompositionCapabilities() -> MatchCapabilities {
    MatchCapabilities(
      canRespond: false,
      canManageAvailability: true,
      canManageComposition: true,
      canPublish: false,
      canStartMatch: false,
      canManageEvents: false,
      canUpdateScore: false,
      canFinishMatch: false
    )
  }

  static func copy(
    _ match: MatchDetail,
    status: MatchStatus? = nil,
    homeScore: Int? = nil,
    awayScore: Int? = nil,
    isCompositionLocked: Bool? = nil,
    composition: TeamComposition? = nil
  ) -> MatchDetail {
    MatchDetail(
      id: match.id,
      title: match.title,
      status: status ?? match.status,
      statusLabel: match.statusLabel,
      preparationPhase: match.preparationPhase,
      isPreparationLocked: match.isPreparationLocked,
      isCompositionLocked: isCompositionLocked ?? match.isCompositionLocked,
      compositionLockedAt: match.compositionLockedAt,
      canPublish: match.canPublish,
      publishBlockers: match.publishBlockers,
      myAvailabilityStatus: match.myAvailabilityStatus,
      availabilitySummary: match.availabilitySummary,
      capabilities: match.capabilities,
      opponentTeam: match.opponentTeam,
      location: match.location,
      homeTeamName: match.homeTeamName,
      teamId: match.teamId,
      date: match.date,
      startTime: match.startTime,
      homeScore: homeScore ?? match.homeScore,
      awayScore: awayScore ?? match.awayScore,
      composition: composition ?? match.composition
    )
  }
}

@MainActor
final class MockMatchDetailService: MatchDetailServicing {
  var fetchMatchesHandler: ((MatchFetchCriteria) async throws -> MatchListResponse)?
  var fetchMatchHandler: ((String, Bool) async throws -> MatchDetail)?
  var updateMyAvailabilityHandler: ((String, MatchAvailabilityStatus) async throws -> MyAvailabilityResponse)?
  var createMatchHandler: ((CreateMatchRequest) async throws -> MatchDetail)?
  var fetchMyAvailabilityHandler: ((String) async throws -> MyAvailabilityResponse)?
  var forcePlayerAvailabilityHandler: ((String, String, MatchAvailabilityStatus) async throws -> MatchAvailabilityEntry)?
  var fetchAvailabilityPresentHandler: ((String) async throws -> [MatchPresentMember])?
  var fetchAvailabilityRosterHandler: ((String) async throws -> MatchAvailabilityRoster)?
  var fetchSelectablePlayersHandler: ((String) async throws -> [MatchSelectablePlayer])?
  var fetchEventsHandler: ((String) async throws -> [MatchEvent])?
  var createEventHandler: ((String, CreateMatchEventRequest) async throws -> MatchEvent)?
  var deleteEventHandler: ((String, String) async throws -> Void)?
  var fetchMatchStatsHandler: ((String) async throws -> MatchStatsPayload)?
  var createMatchCompositionHandler: ((String, MatchCompositionSaveRequest) async throws -> MatchDetail)?
  var updateMatchCompositionHandler: ((String, MatchCompositionSaveRequest) async throws -> MatchDetail)?
  var updateMatchCompositionCaptainHandler: ((String, String?) async throws -> MatchDetail)?
  var lockMatchCompositionHandler: ((String) async throws -> MatchDetail)?
  var publishMatchHandler: ((String) async throws -> MatchDetail)?
  var updateMatchStatusHandler: ((String, MatchStatus) async throws -> MatchDetail)?
  var updateScoreHandler: ((String, Int, Int) async throws -> MatchDetail)?
  var updateMatchHandler: ((String, UpdateMatchRequest) async throws -> MatchDetail)?

  var lastFetchCriteria: MatchFetchCriteria?
  var lastAvailabilityUpdate: (matchId: String, status: MatchAvailabilityStatus)?

  func fetchMatches(criteria: MatchFetchCriteria) async throws -> MatchListResponse {
    lastFetchCriteria = criteria
    if let fetchMatchesHandler {
      return try await fetchMatchesHandler(criteria)
    }
    return MatchListResponse()
  }

  func fetchMatch(id: String, authenticated: Bool) async throws -> MatchDetail {
    if let fetchMatchHandler {
      return try await fetchMatchHandler(id, authenticated)
    }
    throw MatchServiceError.requestFailed("missing handler")
  }

  func updateMyAvailability(
    matchId: String,
    status: MatchAvailabilityStatus
  ) async throws -> MyAvailabilityResponse {
    lastAvailabilityUpdate = (matchId, status)
    if let updateMyAvailabilityHandler {
      return try await updateMyAvailabilityHandler(matchId, status)
    }
    return try JSONDecoder().decode(MyAvailabilityResponse.self, from: Data("{\"status\":\"available\"}".utf8))
  }

  func createMatch(request: CreateMatchRequest) async throws -> MatchDetail {
    if let createMatchHandler {
      return try await createMatchHandler(request)
    }
    throw MatchServiceError.requestFailed("missing handler")
  }

  func fetchMyAvailability(matchId: String) async throws -> MyAvailabilityResponse {
    if let fetchMyAvailabilityHandler {
      return try await fetchMyAvailabilityHandler(matchId)
    }
    return try JSONDecoder().decode(MyAvailabilityResponse.self, from: Data("{\"status\":\"unknown\"}".utf8))
  }

  func forcePlayerAvailability(
    matchId: String,
    playerId: String,
    status: MatchAvailabilityStatus
  ) async throws -> MatchAvailabilityEntry {
    if let forcePlayerAvailabilityHandler {
      return try await forcePlayerAvailabilityHandler(matchId, playerId, status)
    }
    throw MatchServiceError.requestFailed("missing handler")
  }

  func fetchAvailabilityPresent(matchId: String) async throws -> [MatchPresentMember] {
    if let fetchAvailabilityPresentHandler {
      return try await fetchAvailabilityPresentHandler(matchId)
    }
    return []
  }

  func fetchAvailabilityRoster(matchId: String) async throws -> MatchAvailabilityRoster {
    if let fetchAvailabilityRosterHandler {
      return try await fetchAvailabilityRosterHandler(matchId)
    }
    return MatchAvailabilityRoster()
  }

  func fetchSelectablePlayers(matchId: String) async throws -> [MatchSelectablePlayer] {
    if let fetchSelectablePlayersHandler {
      return try await fetchSelectablePlayersHandler(matchId)
    }
    return []
  }

  func fetchEvents(matchId: String) async throws -> [MatchEvent] {
    if let fetchEventsHandler {
      return try await fetchEventsHandler(matchId)
    }
    return []
  }

  func createEvent(matchId: String, request: CreateMatchEventRequest) async throws -> MatchEvent {
    if let createEventHandler {
      return try await createEventHandler(matchId, request)
    }
    throw MatchServiceError.requestFailed("missing handler")
  }

  func deleteEvent(matchId: String, eventId: String) async throws {
    if let deleteEventHandler {
      try await deleteEventHandler(matchId, eventId)
      return
    }
    throw MatchServiceError.requestFailed("missing handler")
  }

  func fetchMatchStats(matchId: String) async throws -> MatchStatsPayload {
    if let fetchMatchStatsHandler {
      return try await fetchMatchStatsHandler(matchId)
    }
    throw MatchServiceError.requestFailed("missing handler")
  }

  func createMatchComposition(
    matchId: String,
    request: MatchCompositionSaveRequest
  ) async throws -> MatchDetail {
    if let createMatchCompositionHandler {
      return try await createMatchCompositionHandler(matchId, request)
    }
    throw MatchServiceError.requestFailed("missing handler")
  }

  func updateMatchComposition(
    matchId: String,
    request: MatchCompositionSaveRequest
  ) async throws -> MatchDetail {
    if let updateMatchCompositionHandler {
      return try await updateMatchCompositionHandler(matchId, request)
    }
    throw MatchServiceError.requestFailed("missing handler")
  }

  func updateMatchCompositionCaptain(matchId: String, captainId: String?) async throws -> MatchDetail {
    if let updateMatchCompositionCaptainHandler {
      return try await updateMatchCompositionCaptainHandler(matchId, captainId)
    }
    throw MatchServiceError.requestFailed("missing handler")
  }

  func lockMatchComposition(matchId: String) async throws -> MatchDetail {
    if let lockMatchCompositionHandler {
      return try await lockMatchCompositionHandler(matchId)
    }
    throw MatchServiceError.requestFailed("missing handler")
  }

  func publishMatch(id: String) async throws -> MatchDetail {
    if let publishMatchHandler {
      return try await publishMatchHandler(id)
    }
    throw MatchServiceError.requestFailed("missing handler")
  }

  func updateMatchStatus(id: String, status: MatchStatus) async throws -> MatchDetail {
    if let updateMatchStatusHandler {
      return try await updateMatchStatusHandler(id, status)
    }
    throw MatchServiceError.requestFailed("missing handler")
  }

  func updateScore(matchId: String, scoreHome: Int, scoreAway: Int) async throws -> MatchDetail {
    if let updateScoreHandler {
      return try await updateScoreHandler(matchId, scoreHome, scoreAway)
    }
    throw MatchServiceError.requestFailed("missing handler")
  }

  func updateMatch(id: String, request: UpdateMatchRequest) async throws -> MatchDetail {
    if let updateMatchHandler {
      return try await updateMatchHandler(id, request)
    }
    throw MatchServiceError.requestFailed("missing handler")
  }
}

typealias MockMatchListingService = MockMatchDetailService

@MainActor
final class MockCompositionService: CompositionServicing {
  var fetchTeamCompositionsHandler: ((String) async throws -> [TeamComposition])?
  var createCompositionHandler: ((CompositionSaveRequest) async throws -> TeamComposition)?
  var updateCompositionHandler: ((String, CompositionSaveRequest) async throws -> TeamComposition)?
  var updateCompositionCaptainHandler: ((String, String?) async throws -> TeamComposition)?
  var deleteCompositionHandler: ((String) async throws -> Void)?
  var deleteAlternativeFormationHandler: ((String, String) async throws -> Void)?

  func fetchTeamCompositions(teamId: String) async throws -> [TeamComposition] {
    if let fetchTeamCompositionsHandler {
      return try await fetchTeamCompositionsHandler(teamId)
    }
    return []
  }

  func createComposition(_ request: CompositionSaveRequest) async throws -> TeamComposition {
    if let createCompositionHandler {
      return try await createCompositionHandler(request)
    }
    throw TeamServiceError.requestFailed("missing handler")
  }

  func updateComposition(id: String, request: CompositionSaveRequest) async throws -> TeamComposition {
    if let updateCompositionHandler {
      return try await updateCompositionHandler(id, request)
    }
    throw TeamServiceError.requestFailed("missing handler")
  }

  func updateCompositionCaptain(id: String, captainId: String?) async throws -> TeamComposition {
    if let updateCompositionCaptainHandler {
      return try await updateCompositionCaptainHandler(id, captainId)
    }
    throw TeamServiceError.requestFailed("missing handler")
  }

  func deleteComposition(id: String) async throws {
    if let deleteCompositionHandler {
      try await deleteCompositionHandler(id)
      return
    }
    throw TeamServiceError.requestFailed("missing handler")
  }

  func deleteAlternativeFormation(compositionId: String, alternativeId: String) async throws {
    if let deleteAlternativeFormationHandler {
      try await deleteAlternativeFormationHandler(compositionId, alternativeId)
      return
    }
    throw TeamServiceError.requestFailed("missing handler")
  }
}

@MainActor
final class MockTeamManagementService: TeamManagementServicing {
  var fetchTeamJoinRequestsHandler: ((String, TeamJoinRequestStatus?) async throws -> [TeamJoinRequest])?
  var reviewJoinRequestHandler: ((String, String, TeamJoinRequestReviewAction) async throws -> Void)?
  var fetchTeamInvitationsHandler: ((String) async throws -> [TeamInvitation])?
  var invitePlayerHandler: ((String, String, String?, String?) async throws -> Void)?
  var resendInvitationHandler: ((String) async throws -> Void)?
  var cancelInvitationHandler: ((String) async throws -> Void)?
  var addGuestHandler: ((String, CreateGuestRequest) async throws -> Void)?
  var deleteGuestHandler: ((String) async throws -> Void)?
  var mergeGuestHandler: ((String, String) async throws -> Void)?
  var updateMemberRoleHandler: ((String, String, TeamRole) async throws -> SquadTeam)?
  var removeMemberHandler: ((String, String) async throws -> Void)?

  var lastInvitedEmail: String?

  func fetchTeamJoinRequests(
    teamId: String,
    status: TeamJoinRequestStatus?
  ) async throws -> [TeamJoinRequest] {
    if let fetchTeamJoinRequestsHandler {
      return try await fetchTeamJoinRequestsHandler(teamId, status)
    }
    return []
  }

  func reviewJoinRequest(
    teamId: String,
    requestId: String,
    action: TeamJoinRequestReviewAction
  ) async throws {
    if let reviewJoinRequestHandler {
      try await reviewJoinRequestHandler(teamId, requestId, action)
      return
    }
    throw TeamServiceError.requestFailed("missing handler")
  }

  func fetchTeamInvitations(teamId: String) async throws -> [TeamInvitation] {
    if let fetchTeamInvitationsHandler {
      return try await fetchTeamInvitationsHandler(teamId)
    }
    return []
  }

  func invitePlayer(
    teamId: String,
    email: String,
    firstName: String?,
    lastName: String?
  ) async throws {
    lastInvitedEmail = email
    if let invitePlayerHandler {
      try await invitePlayerHandler(teamId, email, firstName, lastName)
      return
    }
    throw TeamServiceError.requestFailed("missing handler")
  }

  func resendInvitation(invitationId: String) async throws {
    if let resendInvitationHandler {
      try await resendInvitationHandler(invitationId)
      return
    }
    throw TeamServiceError.requestFailed("missing handler")
  }

  func cancelInvitation(invitationId: String) async throws {
    if let cancelInvitationHandler {
      try await cancelInvitationHandler(invitationId)
      return
    }
    throw TeamServiceError.requestFailed("missing handler")
  }

  func addGuest(teamId: String, request: CreateGuestRequest) async throws {
    if let addGuestHandler {
      try await addGuestHandler(teamId, request)
      return
    }
    throw TeamServiceError.requestFailed("missing handler")
  }

  func deleteGuest(guestId: String) async throws {
    if let deleteGuestHandler {
      try await deleteGuestHandler(guestId)
      return
    }
    throw TeamServiceError.requestFailed("missing handler")
  }

  func mergeGuest(guestId: String, userId: String) async throws {
    if let mergeGuestHandler {
      try await mergeGuestHandler(guestId, userId)
      return
    }
    throw TeamServiceError.requestFailed("missing handler")
  }

  func updateMemberRole(
    teamId: String,
    memberId: String,
    role: TeamRole
  ) async throws -> SquadTeam {
    if let updateMemberRoleHandler {
      return try await updateMemberRoleHandler(teamId, memberId, role)
    }
    throw TeamServiceError.requestFailed("missing handler")
  }

  func removeMember(teamId: String, memberId: String) async throws {
    if let removeMemberHandler {
      try await removeMemberHandler(teamId, memberId)
      return
    }
    throw TeamServiceError.requestFailed("missing handler")
  }
}

@MainActor
final class MockStatsService: ProfileStatsServicing {
  var fetchAvailableSeasonsHandler: (() async -> [String])?
  var fetchTeamSeasonStatsHandler: ((String, String) async throws -> TeamSeasonStatsPayload?)?
  var fetchTeamSeasonRankingsHandler: ((String, String) async throws -> TeamSeasonRankings?)?
  var fetchTeamSeasonInsightsHandler: ((String, String) async throws -> TeamSeasonInsightsPayload?)?
  var fetchTeamSeasonDuosHandler: ((String, String, Int) async throws -> TeamSeasonDuosPayload?)?
  var fetchUserSeasonStatsHandler: ((String, String) async -> UserSeasonStats?)?

  func fetchAvailableSeasons() async -> [String] {
    if let fetchAvailableSeasonsHandler {
      return await fetchAvailableSeasonsHandler()
    }
    return ["2025-2026"]
  }

  func fetchTeamSeasonStats(
    teamId: String,
    season: String
  ) async throws -> TeamSeasonStatsPayload? {
    if let fetchTeamSeasonStatsHandler {
      return try await fetchTeamSeasonStatsHandler(teamId, season)
    }
    return nil
  }

  func fetchTeamSeasonRankings(
    teamId: String,
    season: String
  ) async throws -> TeamSeasonRankings? {
    if let fetchTeamSeasonRankingsHandler {
      return try await fetchTeamSeasonRankingsHandler(teamId, season)
    }
    return nil
  }

  func fetchTeamSeasonInsights(
    teamId: String,
    season: String
  ) async throws -> TeamSeasonInsightsPayload? {
    if let fetchTeamSeasonInsightsHandler {
      return try await fetchTeamSeasonInsightsHandler(teamId, season)
    }
    return nil
  }

  func fetchTeamSeasonDuos(
    teamId: String,
    season: String,
    limit: Int
  ) async throws -> TeamSeasonDuosPayload? {
    if let fetchTeamSeasonDuosHandler {
      return try await fetchTeamSeasonDuosHandler(teamId, season, limit)
    }
    return nil
  }

  func fetchUserSeasonStats(userId: String, season: String) async -> UserSeasonStats? {
    if let fetchUserSeasonStatsHandler {
      return await fetchUserSeasonStatsHandler(userId, season)
    }
    return nil
  }
}

@MainActor
final class MockQuizService: QuizServicing {
  var fetchQuizzesHandler: ((String) async throws -> [MatchQuizSummary])?
  var fetchQuizHandler: ((String) async throws -> MatchQuizDetail)?
  var createQuizHandler: ((String) async throws -> MatchQuizDetail)?
  var updateQuizHandler: ((String, MatchQuizPatchRequest) async throws -> MatchQuizDetail)?
  var deleteQuizHandler: ((String) async throws -> Void)?
  var submitQuizHandler: ((String, MatchQuizSubmitRequest) async throws -> MatchQuizSubmitResult)?
  var fetchUserSubmissionHandler: ((String) async throws -> MatchQuizUserSubmission?)?
  var fetchLeaderboardHandler: ((String) async throws -> MatchQuizLeaderboardResponse)?

  func fetchQuizzesForMatch(matchId: String) async throws -> [MatchQuizSummary] {
    if let fetchQuizzesHandler {
      return try await fetchQuizzesHandler(matchId)
    }
    return []
  }

  func fetchQuiz(id: String) async throws -> MatchQuizDetail {
    if let fetchQuizHandler {
      return try await fetchQuizHandler(id)
    }
    throw QuizServiceError.requestFailed("missing handler")
  }

  func createQuiz(matchId: String) async throws -> MatchQuizDetail {
    if let createQuizHandler {
      return try await createQuizHandler(matchId)
    }
    throw QuizServiceError.requestFailed("missing handler")
  }

  func updateQuiz(id: String, request: MatchQuizPatchRequest) async throws -> MatchQuizDetail {
    if let updateQuizHandler {
      return try await updateQuizHandler(id, request)
    }
    throw QuizServiceError.requestFailed("missing handler")
  }

  func deleteQuiz(id: String) async throws {
    if let deleteQuizHandler {
      try await deleteQuizHandler(id)
      return
    }
    throw QuizServiceError.requestFailed("missing handler")
  }

  func submitQuiz(id: String, request: MatchQuizSubmitRequest) async throws -> MatchQuizSubmitResult {
    if let submitQuizHandler {
      return try await submitQuizHandler(id, request)
    }
    throw QuizServiceError.requestFailed("missing handler")
  }

  func fetchUserSubmission(quizId: String) async throws -> MatchQuizUserSubmission? {
    if let fetchUserSubmissionHandler {
      return try await fetchUserSubmissionHandler(quizId)
    }
    return nil
  }

  func fetchLeaderboard(quizId: String) async throws -> MatchQuizLeaderboardResponse {
    if let fetchLeaderboardHandler {
      return try await fetchLeaderboardHandler(quizId)
    }
    throw QuizServiceError.requestFailed("missing handler")
  }
}

@MainActor
final class MockSportProfileService: SportProfileServicing {
  var fetchProfileHandler: (() async -> SportProfileResponse)?
  var saveProfileHandler: ((SportProfileRequest) async -> SportProfileResponse)?
  var uploadProfilePictureHandler: ((UIImage) async -> ProfilePictureResponse)?

  func fetchProfile() async -> SportProfileResponse {
    if let fetchProfileHandler {
      return await fetchProfileHandler()
    }
    return SportProfileResponse(success: false)
  }

  func saveProfile(_ request: SportProfileRequest) async -> SportProfileResponse {
    if let saveProfileHandler {
      return await saveProfileHandler(request)
    }
    return SportProfileResponse(success: false)
  }

  func uploadProfilePicture(_ image: UIImage) async -> ProfilePictureResponse {
    if let uploadProfilePictureHandler {
      return await uploadProfilePictureHandler(image)
    }
    return ProfilePictureResponse(success: false)
  }
}

final class MockReferenceDataService: ReferenceDataServicing {
  var teamsByLeague: [String: [String]] = [
    FootballLeague.ligue1.rawValue: ["PSG", "OM"],
  ]

  func leagues() -> [LeagueReference] { [] }

  func teams(forLeague leagueKey: String) -> [String] {
    teamsByLeague[leagueKey] ?? []
  }
}

@MainActor
final class MockAccountService: AccountServicing {
  var requestAccountDeletionHandler: (() async -> AccountActionResponse)?
  var cancelAccountDeletionHandler: (() async -> AccountActionResponse)?

  func requestAccountDeletion() async -> AccountActionResponse {
    if let requestAccountDeletionHandler {
      return await requestAccountDeletionHandler()
    }
    return AccountActionResponse(success: false)
  }

  func cancelAccountDeletion() async -> AccountActionResponse {
    if let cancelAccountDeletionHandler {
      return await cancelAccountDeletionHandler()
    }
    return AccountActionResponse(success: false)
  }
}

final class MockOnboardingStore: OnboardingStoring {
  var hasCompletedOnboarding = false

  func markOnboardingCompleted() {
    hasCompletedOnboarding = true
  }
}

@MainActor
final class MockNotificationService: NotificationServicing {
  var fetchNotificationsHandler: ((NotificationFetchCriteria) async throws -> NotificationListResponse)?
  var fetchUnreadCountHandler: (() async throws -> Int)?
  var markAsReadHandler: ((String) async throws -> Void)?
  var markAllAsReadHandler: (() async throws -> Void)?
  var archiveHandler: ((String) async throws -> Void)?
  var unarchiveHandler: ((String) async throws -> Void)?

  func fetchNotifications(criteria: NotificationFetchCriteria) async throws -> NotificationListResponse {
    if let fetchNotificationsHandler {
      return try await fetchNotificationsHandler(criteria)
    }
    return try ViewModelTestFixtures.notificationListResponse()
  }

  func fetchUnreadCount() async throws -> Int {
    if let fetchUnreadCountHandler {
      return try await fetchUnreadCountHandler()
    }
    return 0
  }

  func markAsRead(notificationId: String) async throws {
    if let markAsReadHandler {
      try await markAsReadHandler(notificationId)
      return
    }
  }

  func markAllAsRead() async throws {
    if let markAllAsReadHandler {
      try await markAllAsReadHandler()
      return
    }
  }

  func archive(notificationId: String) async throws {
    if let archiveHandler {
      try await archiveHandler(notificationId)
      return
    }
  }

  func unarchive(notificationId: String) async throws {
    if let unarchiveHandler {
      try await unarchiveHandler(notificationId)
      return
    }
  }
}

final class MockRemoteContentFetcher: RemoteContentFetching {
  var dataHandler: ((URL) async throws -> (Data, URLResponse))?

  func data(from url: URL) async throws -> (Data, URLResponse) {
    if let dataHandler {
      return try await dataHandler(url)
    }
    let response = HTTPURLResponse(
      url: url,
      statusCode: 200,
      httpVersion: nil,
      headerFields: nil
    )!
    return (Data("# Legal".utf8), response)
  }
}

final class MockAPIConfiguration: APIConfiguring {
  var environment: APIEnvironment = .dev
  var customBaseURL = ""

  var resolvedBaseURL: String {
    switch environment {
    case .production, .dev:
      return environment.defaultBaseURL
    case .custom:
      return customBaseURL
    }
  }

  var healthCheckURL: String? {
    let base = resolvedBaseURL.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !base.isEmpty, let baseURL = URL(string: base) else { return nil }
    return baseURL.appending(path: "api/health").absoluteString
  }
}

@MainActor
final class MockPushNotificationManager: PushNotificationTesting {
  var sendTestPushHandler: ((Bool) async throws -> Void)?
  var sendTestPushCallCount = 0

  func sendTestPushNotification(allowProduction: Bool) async throws {
    sendTestPushCallCount += 1
    if let sendTestPushHandler {
      try await sendTestPushHandler(allowProduction)
    }
  }
}
