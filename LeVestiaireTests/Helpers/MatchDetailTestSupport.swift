//
//  MatchDetailTestSupport.swift
//  LeVestiaireTests
//

import Foundation
@testable import LeVestiaire

@MainActor
enum MatchDetailTestSupport {
  static func makeViewModel(
    match: MatchDetail,
    matchService: MockMatchDetailService,
    auth: MockAuthService? = nil,
    teamService: MockTeamJoinService? = nil,
    quizService: MockQuizService? = nil,
    compositionService: MockCompositionService? = nil,
    canManageMatchTeam: Bool = false
  ) -> MatchDetailViewModel {
    let auth = auth ?? MockAuthService()
    let teamService = teamService ?? MockTeamJoinService()
    let quizService = quizService ?? MockQuizService()
    let compositionService = compositionService ?? MockCompositionService()
    let availabilityViewModel = MatchDetailAvailabilityViewModel(matchService: matchService)
    let eventsViewModel = MatchDetailEventsViewModel(matchService: matchService)
    let compositionViewModel = MatchDetailCompositionViewModel(
      matchService: matchService,
      compositionService: compositionService
    )
    let quizViewModel = MatchDetailQuizViewModel(
      quizService: quizService,
      teamService: teamService
    )
    let viewModel = MatchDetailViewModel(
      matchId: match.id,
      matchService: matchService,
      compositionService: compositionService,
      teamService: teamService,
      authService: auth,
      availabilityViewModel: availabilityViewModel,
      compositionViewModel: compositionViewModel,
      quizViewModel: quizViewModel,
      eventsViewModel: eventsViewModel
    )
    viewModel.applyPreviewState(match: match, canManageMatchTeam: canManageMatchTeam)
    return viewModel
  }
}
