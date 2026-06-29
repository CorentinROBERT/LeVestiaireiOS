//
//  MatchDetailQuizViewModel.swift
//  LeVestaire
//

import Combine
import Foundation

@MainActor
final class MatchDetailQuizViewModel: ObservableObject {
    @Published var matchQuizzes: [MatchQuizSummary] = []
    @Published var activeQuizDetail: MatchQuizDetail?
    @Published var quizUserSubmission: MatchQuizUserSubmission?
    @Published var quizLeaderboard: [MatchQuizLeaderboardEntry] = []
    @Published var quizLeaderboardCounts: MatchQuizLeaderboardCounts?
    @Published var quizTeamMembers: [TeamMember] = []
    @Published var isLoadingQuizDetail = false
    @Published var quizSubmitFeedback: MatchQuizSubmitResult?
    @Published var selectedQuizId: String?
    @Published var isLoadingQuizzes = false
    @Published var hasLoadedQuizzes = false
    @Published var isSubmitting = false

    private weak var host: MatchDetailViewModel?
    private let quizService: any QuizServicing
    private let teamService: any TeamDetailServicing

    init(quizService: any QuizServicing, teamService: any TeamDetailServicing) {
        self.quizService = quizService
        self.teamService = teamService
    }

    func attach(to host: MatchDetailViewModel) {
        self.host = host
    }

    var primaryQuiz: MatchQuizSummary? {
        matchQuizzes.first
    }

    var canManage: Bool {
        host?.canManageMatchTeam == true
    }

    var isExcludedPlayer: Bool {
        MatchQuizEligibility.isExcludedFromQuiz(
            userId: host?.currentUserId,
            eligibleUserIds: activeQuizDetail?.eligibleUserIds ?? [],
            teamMembers: quizTeamMembers,
            composition: host?.match?.composition
        )
    }

    var canParticipate: Bool {
        MatchQuizEligibility.canParticipate(
            userId: host?.currentUserId,
            eligibleUserIds: activeQuizDetail?.eligibleUserIds ?? [],
            teamMembers: quizTeamMembers,
            composition: host?.match?.composition
        )
    }

    var hasCompletedSubmission: Bool {
        quizUserSubmission?.isComplete == true
    }

    func resetCache() {
        hasLoadedQuizzes = false
        matchQuizzes = []
        activeQuizDetail = nil
        quizUserSubmission = nil
        quizLeaderboard = []
        quizLeaderboardCounts = nil
        quizSubmitFeedback = nil
        selectedQuizId = nil
        quizTeamMembers = []
    }

    func loadIfNeeded(force: Bool = false) async {
        guard let match = host?.match else { return }
        guard match.status == .finished else { return }
        guard force || !hasLoadedQuizzes else { return }

        isLoadingQuizzes = true
        defer { isLoadingQuizzes = false }

        do {
            await loadTeamMembersIfNeeded()
            matchQuizzes = try await quizService.fetchQuizzesForMatch(matchId: host?.matchId ?? "")
            hasLoadedQuizzes = true

            if let quizId = selectedQuizId ?? matchQuizzes.first?.id {
                await loadContext(quizId: quizId)
            } else {
                activeQuizDetail = nil
                quizUserSubmission = nil
                applyLeaderboardResponse(nil)
            }
        } catch {
            if isCancellationError(error) { return }
            matchQuizzes = []
            surfaceError(error)
        }
    }

    func loadContext(quizId: String) async {
        selectedQuizId = quizId
        isLoadingQuizDetail = true
        quizSubmitFeedback = nil
        defer { isLoadingQuizDetail = false }

        do {
            async let detailTask = quizService.fetchQuiz(id: quizId)
            async let submissionTask = quizService.fetchUserSubmission(quizId: quizId)

            let detail = try await detailTask
            activeQuizDetail = detail
            quizUserSubmission = try await submissionTask

            if detail.resolvedStatus.showsLeaderboard || isExcludedPlayer {
                let leaderboard = try await quizService.fetchLeaderboard(quizId: quizId)
                applyLeaderboardResponse(leaderboard)
            } else {
                applyLeaderboardResponse(nil)
            }
        } catch {
            surfaceError(error)
        }
    }

    func createForMatch() async -> Bool {
        guard canManage, let matchId = host?.matchId else { return false }

        isSubmitting = true
        defer { isSubmitting = false }

        do {
            let detail = try await quizService.createQuiz(matchId: matchId)
            matchQuizzes = [MatchQuizSummary(id: detail.id, title: detail.title, status: detail.status)]
            selectedQuizId = detail.id
            activeQuizDetail = detail
            hasLoadedQuizzes = true
            return true
        } catch {
            surfaceError(error)
            return false
        }
    }

    func saveDraft(title: String, questions: [MatchQuizQuestion]) async -> Bool {
        guard canManage, let quizId = activeQuizDetail?.id else { return false }
        guard questions.count == 10 else {
            host?.errorMessage = L10n.text("quizRulesNotSatisfied")
            return false
        }

        isSubmitting = true
        defer { isSubmitting = false }

        let locale = patchLocale
        let draftQuestions = questions.map { $0.draftQuestionPatch(locale: locale) }

        do {
            _ = try await quizService.updateQuiz(
                id: quizId,
                request: MatchQuizPatchRequest(
                    title: title.nilIfWhitespace,
                    draftQuestions: draftQuestions
                )
            )
            let detail = try await quizService.fetchQuiz(id: quizId)
            activeQuizDetail = detail
            refreshQuizSummary(from: detail)
            return true
        } catch {
            surfaceError(error)
            return false
        }
    }

    func publish(title: String, questions: [MatchQuizQuestion]) async -> Bool {
        guard canManage, let quizId = activeQuizDetail?.id else { return false }
        guard questions.count == 10,
              questions.allSatisfy(\.hasDefinedAnswer),
              questions.contains(where: { $0.correctAnswer == false }) else {
            host?.errorMessage = L10n.text("quizRulesNotSatisfied")
            return false
        }

        isSubmitting = true
        defer { isSubmitting = false }

        let locale = patchLocale
        let draftQuestions = questions.map { $0.draftQuestionPatch(locale: locale) }

        do {
            _ = try await quizService.updateQuiz(
                id: quizId,
                request: MatchQuizPatchRequest(
                    title: title.nilIfWhitespace,
                    status: "open",
                    draftQuestions: draftQuestions
                )
            )
            let updated = try await quizService.fetchQuiz(id: quizId)
            activeQuizDetail = updated
            refreshQuizSummary(from: updated)
            return true
        } catch {
            surfaceError(error)
            return false
        }
    }

    func close() async -> Bool {
        guard canManage, let quizId = activeQuizDetail?.id else { return false }

        isSubmitting = true
        defer { isSubmitting = false }

        do {
            _ = try await quizService.updateQuiz(
                id: quizId,
                request: MatchQuizPatchRequest(status: "closed")
            )
            let updated = try await quizService.fetchQuiz(id: quizId)
            activeQuizDetail = updated
            refreshQuizSummary(from: updated)
            let leaderboard = try await quizService.fetchLeaderboard(quizId: quizId)
            applyLeaderboardResponse(leaderboard)
            return true
        } catch {
            surfaceError(error)
            return false
        }
    }

    func delete() async -> Bool {
        guard canManage, let quizId = activeQuizDetail?.id else { return false }

        isSubmitting = true
        defer { isSubmitting = false }

        do {
            try await quizService.deleteQuiz(id: quizId)
            matchQuizzes = []
            activeQuizDetail = nil
            quizUserSubmission = nil
            applyLeaderboardResponse(nil)
            selectedQuizId = nil
            return true
        } catch {
            surfaceError(error)
            return false
        }
    }

    func submitAnswers(_ answers: [MatchQuizAnswerDraft]) async -> MatchQuizSubmitResult? {
        guard canParticipate,
              let quizId = activeQuizDetail?.id,
              activeQuizDetail?.resolvedStatus.isPlayable == true else {
            return nil
        }

        guard answers.count == activeQuizDetail?.questions.count,
              answers.allSatisfy({ $0.answer != nil }) else {
            host?.errorMessage = L10n.text("quizRulesNotSatisfied")
            return nil
        }

        isSubmitting = true
        defer { isSubmitting = false }

        let request = MatchQuizSubmitRequest(
            answers: answers.compactMap { draft in
                guard let answer = draft.answer else { return nil }
                return MatchQuizAnswerSubmission(
                    questionId: draft.questionId,
                    tempId: draft.tempId,
                    answer: answer
                )
            }
        )

        do {
            let result = try await quizService.submitQuiz(id: quizId, request: request)
            quizSubmitFeedback = result
            quizUserSubmission = try await quizService.fetchUserSubmission(quizId: quizId)
            if result.isComplete || activeQuizDetail?.resolvedStatus.showsLeaderboard == true {
                let leaderboard = try await quizService.fetchLeaderboard(quizId: quizId)
                applyLeaderboardResponse(leaderboard)
            }
            return result
        } catch {
            surfaceError(error)
            return nil
        }
    }

    func loadTeamMembersIfNeeded() async {
        guard quizTeamMembers.isEmpty,
              let teamId = host?.match?.teamId,
              !teamId.isEmpty else { return }

        do {
            let team = try await teamService.fetchTeam(id: teamId)
            let guests = (try? await teamService.fetchTeamGuests(teamId: teamId)) ?? []
            quizTeamMembers = team.withGuests(guests).resolvedMembers
        } catch {
            quizTeamMembers = []
        }
    }

    func reloadLeaderboardIfNeeded() async {
        guard let quizId = activeQuizDetail?.id, !quizId.isEmpty else { return }
        guard activeQuizDetail?.resolvedStatus.showsLeaderboard == true
            || canManage
            || isExcludedPlayer else { return }

        do {
            let leaderboard = try await quizService.fetchLeaderboard(quizId: quizId)
            applyLeaderboardResponse(leaderboard)
        } catch {
            if !isCancellationError(error) {
                applyLeaderboardResponse(nil)
            }
        }
    }

    private func applyLeaderboardResponse(_ response: MatchQuizLeaderboardResponse?) {
        quizLeaderboard = response?.entries ?? []
        quizLeaderboardCounts = response?.counts
    }

    private func refreshQuizSummary(from detail: MatchQuizDetail) {
        let summary = MatchQuizSummary(id: detail.id, title: detail.title, status: detail.status)
        if let index = matchQuizzes.firstIndex(where: { $0.id == detail.id }) {
            matchQuizzes[index] = summary
        } else {
            matchQuizzes = [summary]
        }
    }

    private var patchLocale: String {
        LocalizationManager.shared.language.rawValue
    }

    private func surfaceError(_ error: Error) {
        host?.surfaceError(error)
    }

    private func isCancellationError(_ error: Error) -> Bool {
        TaskCancellation.isError(error)
    }
}

private extension String {
    var nilIfWhitespace: String? {
        let trimmed = trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }
}
