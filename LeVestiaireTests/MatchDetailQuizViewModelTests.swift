//
//  MatchDetailQuizViewModelTests.swift
//  LeVestiaireTests
//

import Foundation
import Testing
@testable import LeVestiaire

@MainActor
struct MatchDetailQuizViewModelTests {
  @Test
  func saveDraft_requiresTenQuestions() async {
    let quizService = MockQuizService()
    let match = ViewModelTestFixtures.matchDetail(id: "match-1", status: .finished)
    let viewModel = MatchDetailTestSupport.makeViewModel(
      match: match,
      matchService: MockMatchDetailService(),
      quizService: quizService,
      canManageMatchTeam: true
    )
    viewModel.quizViewModel.activeQuizDetail = MatchQuizDetail(
      id: "quiz-1",
      title: "Quiz",
      status: "draft"
    )

    let didSave = await viewModel.quizViewModel.saveDraft(
      title: "Quiz",
      questions: ViewModelTestFixtures.quizQuestions(count: 5)
    )

    #expect(didSave == false)
    #expect(viewModel.errorMessage == L10n.text("quizRulesNotSatisfied"))
  }

  @Test
  func publish_withValidQuestions_succeeds() async {
    let quizService = MockQuizService()
    let published = MatchQuizDetail(
      id: "quiz-1",
      title: "Quiz",
      status: "open",
      questions: ViewModelTestFixtures.quizQuestions()
    )
    quizService.updateQuizHandler = { _, _ in published }
    quizService.fetchQuizHandler = { _ in published }
    let match = ViewModelTestFixtures.matchDetail(id: "match-1", status: .finished)
    let viewModel = MatchDetailTestSupport.makeViewModel(
      match: match,
      matchService: MockMatchDetailService(),
      quizService: quizService,
      canManageMatchTeam: true
    )
    viewModel.quizViewModel.activeQuizDetail = MatchQuizDetail(
      id: "quiz-1",
      title: "Quiz",
      status: "draft",
      questions: ViewModelTestFixtures.quizQuestions()
    )

    let didPublish = await viewModel.quizViewModel.publish(
      title: "Quiz",
      questions: ViewModelTestFixtures.quizQuestions()
    )

    #expect(didPublish)
    #expect(viewModel.quizViewModel.activeQuizDetail?.resolvedStatus == .open)
  }

  @Test
  func createForMatch_requiresManagementRights() async {
    let quizService = MockQuizService()
    let match = ViewModelTestFixtures.matchDetail(id: "match-1", status: .finished)
    let viewModel = MatchDetailTestSupport.makeViewModel(
      match: match,
      matchService: MockMatchDetailService(),
      quizService: quizService,
      canManageMatchTeam: false
    )

    let didCreate = await viewModel.quizViewModel.createForMatch()

    #expect(didCreate == false)
  }

  @Test
  func isExcludedPlayer_whenUserIsInLineup() {
    let auth = MockAuthService()
    auth.currentUser = ViewModelTestFixtures.user
    let composition = TeamPreviewData.compositions.first
    let match = ViewModelTestFixtures.matchDetail(
      id: "match-1",
      status: .finished,
      composition: composition
    )
    let viewModel = MatchDetailTestSupport.makeViewModel(
      match: match,
      matchService: MockMatchDetailService(),
      auth: auth
    )
    viewModel.quizViewModel.quizTeamMembers = TeamPreviewData.members
    viewModel.quizViewModel.activeQuizDetail = MatchQuizDetail(
      id: "quiz-1",
      status: "open"
    )

    #expect(viewModel.quizViewModel.isExcludedPlayer)
    #expect(viewModel.quizViewModel.canParticipate == false)
  }
}
