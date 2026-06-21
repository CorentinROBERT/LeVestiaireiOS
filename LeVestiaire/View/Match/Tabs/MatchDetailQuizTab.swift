//
//  MatchDetailQuizTab.swift
//  LeVestaire
//

import SwiftUI

struct MatchDetailQuizTab: View {
    @ObservedObject var viewModel: MatchDetailViewModel
    let match: MatchDetail

    var body: some View {
        Group {
            if viewModel.isLoadingQuizzes, viewModel.matchQuizzes.isEmpty {
                ProgressView(L10n.loading)
                    .frame(maxWidth: .infinity, minHeight: 120)
            } else if viewModel.matchQuizzes.isEmpty {
                TeamEmptyState(
                    icon: "questionmark.circle",
                    title: L10n.text("quiz"),
                    message: L10n.text("quizComingSoon")
                )
            } else {
                quizList
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .task {
            await viewModel.loadQuizzesIfNeeded()
        }
    }

    private var quizList: some View {
        VStack(alignment: .leading, spacing: 10) {
            ForEach(viewModel.matchQuizzes) { quiz in
                HStack(alignment: .center, spacing: 12) {
                    Image(systemName: "questionmark.circle.fill")
                        .font(.title3)
                        .foregroundStyle(AppPalette.Primary.main)

                    VStack(alignment: .leading, spacing: 4) {
                        Text(quiz.resolvedTitle)
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(AppPalette.Neutral.textPrimary)

                        Text(quiz.statusLabel)
                            .font(.caption)
                            .foregroundStyle(AppPalette.Neutral.textSecondary)
                    }

                    Spacer(minLength: 0)
                }
                .padding(12)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(AppPalette.Neutral.surface)
                )
            }
        }
    }
}

#if DEBUG
#Preview {
    MatchDetailQuizTab(
        viewModel: .preview(status: .finished),
        match: MatchPreviewData.detail(status: .finished)
    )
    .padding()
    .teamPreviewEnvironment()
}
#endif
