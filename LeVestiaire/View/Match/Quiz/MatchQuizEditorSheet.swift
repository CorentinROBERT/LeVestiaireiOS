//
//  MatchQuizEditorSheet.swift
//  LeVestaire
//

import SwiftUI

struct MatchQuizEditorSheet: View {
    @ObservedObject var matchViewModel: MatchDetailViewModel
    @StateObject private var editorViewModel: MatchQuizEditorViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var showsPublishConfirmation = false
    @State private var showsDeleteConfirmation = false

    init(matchViewModel: MatchDetailViewModel, detail: MatchQuizDetail) {
        self.matchViewModel = matchViewModel
        _editorViewModel = StateObject(wrappedValue: MatchQuizEditorViewModel(detail: detail))
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    UTextField(
                        label: L10n.text("quizTitle"),
                        placeholder: L10n.text("quizTitle"),
                        icon: nil,
                        text: $editorViewModel.title
                    )

                    rulesCard

                    ForEach(Array(editorViewModel.questions.enumerated()), id: \.element.id) { index, question in
                        editorQuestionCard(index: index + 1, question: question)
                    }

                    UButton(
                        text: L10n.text("save"),
                        textColor: AppPalette.Primary.main,
                        backgroundColor: AppPalette.Primary.soft,
                        cornerRadius: 12,
                        isFullWidth: true,
                        onPress: {
                            Task { await saveDraft() }
                        }
                    )

                    UButton(
                        text: L10n.text("publish"),
                        textColor: AppPalette.Primary.onMain,
                        backgroundColor: AppPalette.Primary.main,
                        cornerRadius: 12,
                        isFullWidth: true,
                        onPress: {
                            showsPublishConfirmation = true
                        }
                    )
                    .opacity(editorViewModel.isValidForPublish ? 1 : 0.5)
                    .disabled(!editorViewModel.isValidForPublish || matchViewModel.isSubmitting)
                    .confirmationDialog(
                        L10n.text("publish"),
                        isPresented: $showsPublishConfirmation,
                        titleVisibility: .visible
                    ) {
                        Button(L10n.text("publish")) {
                            Task { await publish() }
                        }
                        Button(L10n.cancel, role: .cancel) {}
                    }

                    if matchViewModel.activeQuizDetail?.resolvedStatus.isPlayable == true {
                        UButton(
                            text: L10n.text("closeQuiz"),
                            textColor: AppPalette.Primary.onMain,
                            backgroundColor: AppPalette.Semantic.warning,
                            cornerRadius: 12,
                            isFullWidth: true,
                            onPress: {
                                Task { await closeQuiz() }
                            }
                        )
                    }

                    Button(L10n.text("deleteQuiz"), role: .destructive) {
                        showsDeleteConfirmation = true
                    }
                    .font(.subheadline.weight(.semibold))
                    .frame(maxWidth: .infinity)
                    .confirmationDialog(
                        L10n.text("deleteQuiz"),
                        isPresented: $showsDeleteConfirmation,
                        titleVisibility: .visible
                    ) {
                        Button(L10n.text("deleteQuiz"), role: .destructive) {
                            Task { await deleteQuiz() }
                        }
                        Button(L10n.cancel, role: .cancel) {}
                    } message: {
                        Text(L10n.text("deleteQuizConfirmation"))
                    }
                }
                .padding(16)
            }
            .background(AppPalette.Neutral.background)
            .navigationTitle(L10n.text("quiz"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(L10n.close) { dismiss() }
                }
            }
        }
    }

    private var rulesCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(L10n.text("quizRulesNotSatisfied"))
                .font(.caption)
                .foregroundStyle(
                    editorViewModel.isValidForPublish
                        ? AppPalette.Semantic.success
                        : AppPalette.Semantic.warning
                )

            Text(
                L10n.format(
                    "quizContainsFalseAnswersToIdentify",
                    editorViewModel.falseAnswersCount
                )
            )
            .font(.caption)
            .foregroundStyle(AppPalette.Neutral.textSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .glassEffect(.regular, in: .rect(cornerRadius: 16))
    }

    private func editorQuestionCard(index: Int, question: MatchQuizQuestion) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("\(L10n.text("questionText")) \(index)")
                .font(.caption.weight(.semibold))
                .foregroundStyle(AppPalette.Neutral.textSecondary)

            if question.isSystemGenerated {
                Text(question.text)
                    .font(.subheadline)
                    .foregroundStyle(AppPalette.Neutral.textPrimary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(12)
                    .background(AppPalette.Neutral.surface, in: RoundedRectangle(cornerRadius: 12))
            } else {
                TextField(L10n.text("questionHint"), text: bindingText(for: question.id), axis: .vertical)
                    .lineLimit(2...4)
                    .padding(12)
                    .background(AppPalette.Neutral.surface, in: RoundedRectangle(cornerRadius: 12))
            }

            Text(L10n.text("isAnswerTrue"))
                .font(.caption.weight(.semibold))
                .foregroundStyle(AppPalette.Neutral.textSecondary)

            Picker("", selection: bindingAnswer(for: question.id)) {
                Text(L10n.text("undefinedAnswer")).tag(Optional<Bool>.none)
                Text(L10n.text("trueValue")).tag(Optional(true))
                Text(L10n.text("falseValue")).tag(Optional(false))
            }
            .pickerStyle(.segmented)
        }
        .padding(14)
        .glassEffect(.regular, in: .rect(cornerRadius: 16))
    }

    private func bindingText(for questionId: String) -> Binding<String> {
        Binding(
            get: {
                editorViewModel.questions.first(where: { $0.id == questionId })?.text ?? ""
            },
            set: { editorViewModel.updateQuestionText(id: questionId, text: $0) }
        )
    }

    private func bindingAnswer(for questionId: String) -> Binding<Bool?> {
        Binding(
            get: {
                editorViewModel.questions.first(where: { $0.id == questionId })?.correctAnswer
            },
            set: { newValue in
                if let value = newValue {
                    editorViewModel.updateQuestionAnswer(id: questionId, isTrue: value)
                } else {
                    editorViewModel.clearQuestionAnswer(id: questionId)
                }
            }
        )
    }

    private func saveDraft() async {
        if await matchViewModel.saveQuizDraft(
            title: editorViewModel.title,
            questions: editorViewModel.questions
        ) {
            editorViewModel.title = matchViewModel.activeQuizDetail?.resolvedTitle ?? editorViewModel.title
        }
    }

    private func publish() async {
        _ = await saveDraft()
        guard editorViewModel.isValidForPublish else { return }
        if await matchViewModel.publishQuiz(
            title: editorViewModel.title,
            questions: editorViewModel.questions
        ) {
            dismiss()
        }
    }

    private func closeQuiz() async {
        if await matchViewModel.closeQuiz() {
            dismiss()
        }
    }

    private func deleteQuiz() async {
        if await matchViewModel.deleteQuiz() {
            dismiss()
        }
    }
}

#if DEBUG
#Preview {
    MatchQuizEditorSheet(
        matchViewModel: .preview(status: .finished),
        detail: .preview
    )
    .teamPreviewEnvironment()
}
#endif
