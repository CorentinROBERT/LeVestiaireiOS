//
//  MatchQuizEditorViewModel.swift
//  LeVestaire
//

import Combine
import Foundation

@MainActor
final class MatchQuizEditorViewModel: ObservableObject {
    @Published var title: String
    @Published var questions: [MatchQuizQuestion]

    init(detail: MatchQuizDetail) {
        title = detail.resolvedTitle
        questions = detail.sortedQuestions
    }

    var falseAnswersCount: Int {
        questions.filter { $0.correctAnswer == false }.count
    }

    var isValidForPublish: Bool {
        questions.count == 10
            && questions.allSatisfy(\.hasDefinedAnswer)
            && falseAnswersCount >= 1
    }

    func updateQuestionText(id: String, text: String) {
        guard let index = questions.firstIndex(where: { $0.id == id }) else { return }
        questions[index].text = text
        if !questions[index].isSystemGenerated {
            questions[index].textRaw = text
        }
    }

    func updateQuestionAnswer(id: String, isTrue: Bool) {
        guard let index = questions.firstIndex(where: { $0.id == id }) else { return }
        questions[index].correctAnswer = isTrue
    }

    func clearQuestionAnswer(id: String) {
        guard let index = questions.firstIndex(where: { $0.id == id }) else { return }
        questions[index].correctAnswer = nil
    }
}
