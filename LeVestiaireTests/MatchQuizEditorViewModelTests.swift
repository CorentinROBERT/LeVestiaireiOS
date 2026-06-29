//
//  MatchQuizEditorViewModelTests.swift
//  LeVestiaireTests
//

import Foundation
import Testing
@testable import LeVestiaire

@MainActor
struct MatchQuizEditorViewModelTests {
  @Test
  func isValidForPublish_requiresTenQuestionsAndFalseAnswer() {
    let incomplete = ViewModelTestFixtures.quizQuestions(count: 5, includesFalseAnswer: true)
    let viewModel = MatchQuizEditorViewModel(
      detail: ViewModelTestFixtures.quizDetail(questions: incomplete)
    )

    #expect(viewModel.isValidForPublish == false)

    let valid = ViewModelTestFixtures.quizQuestions(count: 10, includesFalseAnswer: true)
    let ready = MatchQuizEditorViewModel(
      detail: ViewModelTestFixtures.quizDetail(questions: valid)
    )

    #expect(ready.isValidForPublish)
    #expect(ready.falseAnswersCount >= 1)
  }

  @Test
  func updateQuestionText_updatesCustomQuestion() {
    let question = MatchQuizQuestion(
      id: "q-1",
      text: "Original",
      correctAnswer: true,
      source: "custom"
    )
    let viewModel = MatchQuizEditorViewModel(
      detail: ViewModelTestFixtures.quizDetail(questions: [question])
    )

    viewModel.updateQuestionText(id: "q-1", text: "Updated")

    #expect(viewModel.questions.first?.text == "Updated")
    #expect(viewModel.questions.first?.textRaw == "Updated")
  }

  @Test
  func updateQuestionText_doesNotOverrideSystemRawText() {
    let question = MatchQuizQuestion(
      id: "q-1",
      text: "System",
      correctAnswer: true,
      textRaw: "raw-key",
      source: "system"
    )
    let viewModel = MatchQuizEditorViewModel(
      detail: ViewModelTestFixtures.quizDetail(questions: [question])
    )

    viewModel.updateQuestionText(id: "q-1", text: "Edited display")

    #expect(viewModel.questions.first?.text == "Edited display")
    #expect(viewModel.questions.first?.textRaw == "raw-key")
  }

  @Test
  func updateQuestionAnswer_setsCorrectValue() {
    let question = MatchQuizQuestion(id: "q-1", text: "Question", correctAnswer: nil, source: "custom")
    let viewModel = MatchQuizEditorViewModel(
      detail: ViewModelTestFixtures.quizDetail(questions: [question])
    )

    viewModel.updateQuestionAnswer(id: "q-1", isTrue: false)

    #expect(viewModel.questions.first?.correctAnswer == false)
    #expect(viewModel.falseAnswersCount == 1)
  }

  @Test
  func clearQuestionAnswer_removesDefinedAnswer() {
    let question = MatchQuizQuestion(id: "q-1", text: "Question", correctAnswer: true, source: "custom")
    let viewModel = MatchQuizEditorViewModel(
      detail: ViewModelTestFixtures.quizDetail(questions: [question])
    )

    viewModel.clearQuestionAnswer(id: "q-1")

    #expect(viewModel.questions.first?.correctAnswer == nil)
    #expect(viewModel.isValidForPublish == false)
  }
}
