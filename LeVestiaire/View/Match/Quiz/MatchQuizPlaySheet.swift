//
//  MatchQuizPlaySheet.swift
//  LeVestaire
//

import SwiftUI

struct MatchQuizPlaySheet: View {
    @ObservedObject var quizViewModel: MatchDetailQuizViewModel
    @StateObject private var playViewModel: MatchQuizPlayViewModel
    @Environment(\.dismiss) private var dismiss

    init(quizViewModel: MatchDetailQuizViewModel, quiz: MatchQuizDetail) {
        self.quizViewModel = quizViewModel
        _playViewModel = StateObject(
            wrappedValue: MatchQuizPlayViewModel(
                quiz: quiz,
                existingSubmission: quizViewModel.quizUserSubmission
            )
        )
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    headerCard

                    if playViewModel.isComplete {
                        successCard
                    }

                    if let feedback = playViewModel.lastFeedback, !feedback.isComplete {
                        feedbackCard(feedback)
                    }

                    statementsSection

                    if !playViewModel.isComplete {
                        UButton(
                            text: L10n.text("submitAnswers"),
                            textColor: AppPalette.Primary.onMain,
                            backgroundColor: AppPalette.Primary.main,
                            cornerRadius: 12,
                            isFullWidth: true,
                            onPress: {
                                Task { await submit() }
                            }
                        )
                        .opacity(playViewModel.canSubmit ? 1 : 0.5)
                        .disabled(!playViewModel.canSubmit || playViewModel.isSubmitting)
                    }
                }
                .padding(16)
            }
            .background(AppPalette.Neutral.background)
            .navigationTitle(playViewModel.quiz.resolvedTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(L10n.close) { dismiss() }
                }
            }
        }
    }

    private var headerCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(
                L10n.format(
                    "quizContainsFalseAnswersToIdentify",
                    playViewModel.falseAnswersCount
                )
            )
            .font(.subheadline)
            .foregroundStyle(AppPalette.Neutral.textPrimary)

            if playViewModel.attemptCount > 0 {
                Text(L10n.format("youHaveMadeAttempts", playViewModel.attemptCount))
                    .font(.caption)
                    .foregroundStyle(AppPalette.Neutral.textSecondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .glassEffect(.regular, in: .rect(cornerRadius: 16))
    }

    private var successCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(L10n.text("allFalseAnswersFound"))
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(AppPalette.Semantic.success)

            Text(L10n.format("youHaveMadeAttempts", playViewModel.attemptCount))
                .font(.caption)
                .foregroundStyle(AppPalette.Neutral.textSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(AppPalette.Semantic.success.opacity(0.12), in: RoundedRectangle(cornerRadius: 16))
    }

    private func feedbackCard(_ feedback: MatchQuizSubmitResult) -> some View {
        Text(
            L10n.format(
                "youHaveFoundFalseAnswers",
                feedback.falseFound,
                feedback.falseAnswersCount
            )
        )
        .font(.subheadline.weight(.semibold))
        .foregroundStyle(AppPalette.Primary.main)
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(AppPalette.Primary.soft.opacity(0.35), in: RoundedRectangle(cornerRadius: 16))
    }

    private var statementsSection: some View {
        VStack(spacing: 12) {
            ForEach(Array(playViewModel.quiz.questions.enumerated()), id: \.element.id) { index, question in
                MatchQuizStatementRow(
                    index: index + 1,
                    text: question.text,
                    selection: answerBinding(for: question.id),
                    isEditable: !playViewModel.isComplete
                )
            }
        }
    }

    private func answerBinding(for questionId: String) -> Binding<Bool?> {
        Binding(
            get: {
                playViewModel.answers.first(where: { $0.questionId == questionId })?.answer
            },
            set: { newValue in
                if let value = newValue {
                    playViewModel.setAnswer(questionId: questionId, value: value)
                }
            }
        )
    }

    private func submit() async {
        let result = await quizViewModel.submitAnswers(playViewModel.answers)
        if let result {
            playViewModel.applySubmissionResult(result)
        }
    }
}

#if DEBUG
#Preview {
    MatchQuizPlaySheet(
        quizViewModel: MatchDetailViewModel.preview(status: .finished).quizViewModel,
        quiz: .preview
    )
    .teamPreviewEnvironment()
}
#endif
