//
//  MatchQuizPlayViewModelTests.swift
//  LeVestiaireTests
//

import Foundation
import Testing
@testable import LeVestiaire

@MainActor
struct MatchQuizPlayViewModelTests {
  @Test
  func canSubmit_requiresAllAnswers() throws {
    let questions = ViewModelTestFixtures.quizQuestions(count: 3, includesFalseAnswer: false)
    let quiz = ViewModelTestFixtures.quizDetail(questions: questions)
    let viewModel = MatchQuizPlayViewModel(quiz: quiz, existingSubmission: nil)

    #expect(viewModel.canSubmit == false)

    for question in questions {
      viewModel.setAnswer(questionId: question.id, value: true)
    }

    #expect(viewModel.canSubmit)
  }

  @Test
  func setAnswer_updatesDraft() {
    let questions = [
      MatchQuizQuestion(id: "q-1", text: "Question 1", correctAnswer: true),
      MatchQuizQuestion(id: "q-2", text: "Question 2", correctAnswer: false),
    ]
    let quiz = ViewModelTestFixtures.quizDetail(questions: questions)
    let viewModel = MatchQuizPlayViewModel(quiz: quiz, existingSubmission: nil)

    viewModel.setAnswer(questionId: "q-1", value: false)

    #expect(viewModel.answers.first(where: { $0.questionId == "q-1" })?.answer == false)
  }

  @Test
  func init_loadsProgressFromExistingSubmission() throws {
    let submission = try ViewModelTestFixtures.quizUserSubmission(
      attemptCount: 2,
      isComplete: true
    )
    let viewModel = MatchQuizPlayViewModel(
      quiz: ViewModelTestFixtures.quizDetail(questions: [
        MatchQuizQuestion(id: "q-1", text: "Question 1", correctAnswer: true),
      ]),
      existingSubmission: submission
    )

    #expect(viewModel.attemptCount == 2)
    #expect(viewModel.isComplete)
  }

  @Test
  func applySubmissionResult_updatesProgress() throws {
    let quiz = ViewModelTestFixtures.quizDetail()
    let viewModel = MatchQuizPlayViewModel(quiz: quiz, existingSubmission: nil)
    let result = try ViewModelTestFixtures.quizSubmitResult(
      isComplete: true,
      attemptCount: 3,
      falseFound: 2,
      falseAnswersCount: 2
    )

    viewModel.applySubmissionResult(result)

    #expect(viewModel.isComplete)
    #expect(viewModel.attemptCount == 3)
    #expect(viewModel.lastFeedback == result)
    #expect(viewModel.canSubmit == false)
  }

  @Test
  func falseAnswersCount_usesQuizMetadata() {
    let questions = ViewModelTestFixtures.quizQuestions(count: 10, includesFalseAnswer: true)
    let quiz = MatchQuizDetail(
      id: "quiz-1",
      questions: questions,
      falseAnswersCount: 4
    )
    let viewModel = MatchQuizPlayViewModel(quiz: quiz, existingSubmission: nil)

    #expect(viewModel.falseAnswersCount == 4)
  }
}
