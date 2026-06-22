//
//  MatchDetailQuizTab.swift
//  LeVestaire
//

import SwiftUI

struct MatchDetailQuizTab: View {
    @ObservedObject var viewModel: MatchDetailViewModel
    @ObservedObject var quizViewModel: MatchDetailQuizViewModel
    let match: MatchDetail

    @State private var showEditor = false
    @State private var showPlay = false

    init(viewModel: MatchDetailViewModel, match: MatchDetail) {
        self.viewModel = viewModel
        self.quizViewModel = viewModel.quizViewModel
        self.match = match
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                if isLoadingInitialQuiz {
                    ProgressView(L10n.loading)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 32)
                } else if let quiz = quizViewModel.activeQuizDetail {
                    quizContent(quiz)
                } else if quizViewModel.canManage {
                    emptyManagerState
                } else {
                    emptyPlayerState
                }
            }
            .padding(.horizontal, 4)
            .padding(.vertical, 4)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .sheet(isPresented: $showEditor) {
            if let detail = quizViewModel.activeQuizDetail {
                MatchQuizEditorSheet(quizViewModel: quizViewModel, detail: detail)
            }
        }
        .sheet(isPresented: $showPlay) {
            if let detail = quizViewModel.activeQuizDetail {
                MatchQuizPlaySheet(quizViewModel: quizViewModel, quiz: detail)
            }
        }
    }

    private var isLoadingInitialQuiz: Bool {
        (quizViewModel.isLoadingQuizzes || quizViewModel.isLoadingQuizDetail)
            && quizViewModel.activeQuizDetail == nil
            && quizViewModel.matchQuizzes.isEmpty
    }

    // MARK: - Empty states

    private var emptyManagerState: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(L10n.text("createQuizForMatch"))
                .font(.subheadline)
                .foregroundStyle(AppPalette.Neutral.textSecondary)

            UButton(
                text: L10n.text("createQuiz"),
                textColor: AppPalette.Primary.onMain,
                backgroundColor: AppPalette.Primary.main,
                cornerRadius: 12,
                isFullWidth: true,
                onPress: {
                    Task {
                        if await quizViewModel.createForMatch() {
                            showEditor = true
                        }
                    }
                }
            )
            .opacity(quizViewModel.isSubmitting ? 0.5 : 1)
            .disabled(quizViewModel.isSubmitting)
        }
    }

    private var emptyPlayerState: some View {
        TeamEmptyState(
            icon: "questionmark.circle",
            title: L10n.text("quiz"),
            message: L10n.text("noQuizForMatch")
        )
    }

    // MARK: - Quiz content

    @ViewBuilder
    private func quizContent(_ quiz: MatchQuizDetail) -> some View {
        headerCard(quiz)

        if let error = viewModel.errorMessage {
            Text(error)
                .font(.caption)
                .foregroundStyle(AppPalette.Semantic.error)
        }

        if quizViewModel.canManage {
            managerSection(quiz)
        } else if quizViewModel.isExcludedPlayer {
            excludedSection(quiz)
        } else if quizViewModel.canParticipate {
            playerSection(quiz)
        } else {
            Text(L10n.text("noQuizForMatch"))
                .font(.subheadline)
                .foregroundStyle(AppPalette.Neutral.textSecondary)
        }

        if shouldShowLeaderboard(for: quiz) {
            leaderboardSection
        }
    }

    private func headerCard(_ quiz: MatchQuizDetail) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(quiz.resolvedTitle)
                    .font(.headline)
                Spacer(minLength: 0)
                quizStatusBadge(quiz.resolvedStatus)
            }

            Text(
                L10n.format(
                    "quizContainsFalseAnswersToIdentify",
                    quiz.resolvedFalseAnswersCount
                )
            )
            .font(.subheadline)
            .foregroundStyle(AppPalette.Neutral.textSecondary)
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(AppPalette.Neutral.surface)
        )
    }

    private func quizStatusBadge(_ status: MatchQuizStatus) -> some View {
        Text(statusBadgeLabel(status))
            .font(.caption.weight(.semibold))
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(statusBadgeColor(status).opacity(0.15))
            .foregroundStyle(statusBadgeColor(status))
            .clipShape(Capsule())
    }

    private func statusBadgeLabel(_ status: MatchQuizStatus) -> String {
        switch status {
        case .draft:
            L10n.text("draft")
        case .open:
            L10n.text("quizStatusOpen")
        case .closed, .finished:
            L10n.text("closed")
        case .unknown:
            L10n.text("quizComingSoon")
        }
    }

    private func statusBadgeColor(_ status: MatchQuizStatus) -> Color {
        switch status {
        case .draft:
            AppPalette.Neutral.textSecondary
        case .open:
            AppPalette.Semantic.success
        case .closed, .finished, .unknown:
            AppPalette.Neutral.textTertiary
        }
    }

    // MARK: - Manager

    @ViewBuilder
    private func managerSection(_ quiz: MatchQuizDetail) -> some View {
        if quiz.resolvedStatus.isEditable {
            UButton(
                text: L10n.text("editQuiz"),
                textColor: AppPalette.Primary.main,
                backgroundColor: AppPalette.Primary.soft,
                cornerRadius: 12,
                isFullWidth: true,
                onPress: { showEditor = true }
            )
        }

        if quiz.resolvedStatus.isPlayable {
            VStack(alignment: .leading, spacing: 8) {
                Text(L10n.format("quizParticipantsCount", quiz.participantCount ?? 0))
                    .font(.subheadline)
                if let completed = quiz.completedCount {
                    Text(L10n.format("quizPerfectScoresCount", completed))
                        .font(.caption)
                        .foregroundStyle(AppPalette.Neutral.textSecondary)
                }
            }

            UButton(
                text: L10n.text("closeQuiz"),
                textColor: AppPalette.Primary.onMain,
                backgroundColor: AppPalette.Semantic.warning,
                cornerRadius: 12,
                isFullWidth: true,
                onPress: {
                    Task { await quizViewModel.close() }
                }
            )
            .opacity(quizViewModel.isSubmitting ? 0.5 : 1)
            .disabled(quizViewModel.isSubmitting)
        }

        if quiz.resolvedStatus.isEditable {
            Button(L10n.text("deleteQuiz"), role: .destructive) {
                Task { await quizViewModel.delete() }
            }
            .font(.subheadline.weight(.semibold))
            .frame(maxWidth: .infinity)
            .disabled(quizViewModel.isSubmitting)
        }
    }

    // MARK: - Player

    @ViewBuilder
    private func playerSection(_ quiz: MatchQuizDetail) -> some View {
        if quiz.resolvedStatus.isPlayable {
            if let submission = quizViewModel.quizUserSubmission, submission.isComplete {
                successCard(submission)
            } else {
                playCard(quiz, submission: quizViewModel.quizUserSubmission)
            }
        } else if quiz.resolvedStatus.showsLeaderboard {
            if let submission = quizViewModel.quizUserSubmission {
                closedResultCard(submission)
            } else {
                Text(L10n.text("quizClosedNoParticipation"))
                    .font(.subheadline)
                    .foregroundStyle(AppPalette.Neutral.textSecondary)
            }
        } else {
            Text(L10n.text("quizNotYetPublished"))
                .font(.subheadline)
                .foregroundStyle(AppPalette.Neutral.textSecondary)
        }
    }

    private func playCard(_ quiz: MatchQuizDetail, submission: MatchQuizUserSubmission?) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            if let submission, submission.attemptCount > 0 {
                Text(L10n.format("youHaveMadeAttempts", submission.attemptCount))
                    .font(.subheadline)

                if !submission.isComplete,
                   let found = submission.falseFound {
                    Text(
                        L10n.format(
                            "youHaveFoundFalseAnswers",
                            found,
                            submission.falseAnswersCount ?? quiz.resolvedFalseAnswersCount
                        )
                    )
                    .font(.caption)
                    .foregroundStyle(AppPalette.Neutral.textSecondary)
                }
            }

            UButton(
                text: L10n.text("playQuiz"),
                textColor: AppPalette.Primary.onMain,
                backgroundColor: AppPalette.Primary.main,
                cornerRadius: 12,
                isFullWidth: true,
                onPress: { showPlay = true }
            )
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(AppPalette.Neutral.surface)
        )
    }

    private func successCard(_ submission: MatchQuizUserSubmission) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Label(L10n.text("allFalseAnswersFound"), systemImage: "checkmark.circle.fill")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(AppPalette.Semantic.success)

            Text(L10n.format("youHaveMadeAttempts", submission.attemptCount))
                .font(.caption)
                .foregroundStyle(AppPalette.Neutral.textSecondary)
        }
        .padding(14)
        .background(AppPalette.Semantic.success.opacity(0.08), in: RoundedRectangle(cornerRadius: 12))
    }

    private func closedResultCard(_ submission: MatchQuizUserSubmission) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            if submission.isComplete {
                Label(L10n.text("allFalseAnswersFound"), systemImage: "checkmark.circle.fill")
                    .foregroundStyle(AppPalette.Semantic.success)
            }
            Text(L10n.format("youHaveMadeAttempts", submission.attemptCount))
                .font(.caption)
                .foregroundStyle(AppPalette.Neutral.textSecondary)
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(AppPalette.Neutral.surface)
        )
    }

    // MARK: - Excluded

    private func excludedSection(_ quiz: MatchQuizDetail) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(L10n.text("quizExcludedPlayedMessage"))
                .font(.subheadline)
                .foregroundStyle(AppPalette.Neutral.textSecondary)

            if quiz.resolvedStatus.isPlayable {
                Text(L10n.text("quizLeaderboardAvailableAfterClose"))
                    .font(.caption)
                    .foregroundStyle(AppPalette.Neutral.textTertiary)
            }
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(AppPalette.Neutral.surface)
        )
    }

    // MARK: - Leaderboard

    private func shouldShowLeaderboard(for quiz: MatchQuizDetail) -> Bool {
        quiz.resolvedStatus.showsLeaderboard || quizViewModel.canManage
    }

    private var leaderboardSection: some View {
        MatchQuizLeaderboardView(
            entries: quizViewModel.quizLeaderboard,
            counts: quizViewModel.quizLeaderboardCounts
        )
            .task(id: quizViewModel.activeQuizDetail?.id) {
                await quizViewModel.reloadLeaderboardIfNeeded()
            }
    }
}

#if DEBUG
#Preview("Quiz tab — manager") {
    let match = MatchPreviewData.detail(status: .finished)
    MatchDetailQuizTab(
        viewModel: .preview(status: .finished),
        match: match
    )
    .padding()
    .teamPreviewEnvironment()
}
#endif
