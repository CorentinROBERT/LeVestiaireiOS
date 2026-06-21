//
//  MatchQuizPlayViewModel.swift
//  LeVestaire
//

import Combine
import Foundation

@MainActor
final class MatchQuizPlayViewModel: ObservableObject {
    @Published private(set) var answers: [MatchQuizAnswerDraft] = []
    @Published private(set) var attemptCount: Int = 0
    @Published private(set) var lastFeedback: MatchQuizSubmitResult?
    @Published private(set) var isComplete = false
    @Published var isSubmitting = false

    let quiz: MatchQuizDetail

    init(quiz: MatchQuizDetail, existingSubmission: MatchQuizUserSubmission?) {
        self.quiz = quiz
        self.attemptCount = existingSubmission?.attemptCount ?? 0
        self.isComplete = existingSubmission?.isComplete ?? false
        resetAnswers(from: existingSubmission)
    }

    var falseAnswersCount: Int {
        quiz.resolvedFalseAnswersCount
    }

    var canSubmit: Bool {
        !isComplete
            && !isSubmitting
            && answers.count == quiz.questions.count
            && answers.allSatisfy { $0.answer != nil }
    }

    func setAnswer(questionId: String, value: Bool) {
        guard let index = answers.firstIndex(where: { $0.questionId == questionId }) else { return }
        answers[index].answer = value
    }

    func applySubmissionResult(_ result: MatchQuizSubmitResult) {
        lastFeedback = result
        attemptCount = result.attemptCount
        isComplete = result.isComplete
    }

    func resetAnswers(from submission: MatchQuizUserSubmission?) {
        answers = quiz.questions.map { question in
            let stored = submission?.answers?.first(where: {
                $0.questionId == question.id || $0.tempId == question.tempId
            })
            return MatchQuizAnswerDraft(
                questionId: question.id,
                tempId: question.tempId,
                answer: stored?.answer
            )
        }
    }
}
