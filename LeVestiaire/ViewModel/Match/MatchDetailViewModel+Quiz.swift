//
//  MatchDetailViewModel+Quiz.swift
//  LeVestaire
//

import Foundation

extension MatchDetailViewModel {
    var primaryQuiz: MatchQuizSummary? {
        matchQuizzes.first
    }

    var quizCanManage: Bool {
        canManageMatchTeam
    }

    var quizIsExcludedPlayer: Bool {
        MatchQuizEligibility.isExcludedFromQuiz(
            userId: currentUserId,
            eligibleUserIds: activeQuizDetail?.eligibleUserIds ?? [],
            teamMembers: quizTeamMembers,
            composition: match?.composition
        )
    }

    var quizCanParticipate: Bool {
        MatchQuizEligibility.canParticipate(
            userId: currentUserId,
            eligibleUserIds: activeQuizDetail?.eligibleUserIds ?? [],
            teamMembers: quizTeamMembers,
            composition: match?.composition
        )
    }

    var quizHasCompletedSubmission: Bool {
        quizUserSubmission?.isComplete == true
    }

    func loadQuizzesIfNeeded(force: Bool = false) async {
        guard let match else { return }
        guard match.status == .finished else { return }
        guard force || !hasLoadedQuizzes else { return }

        isLoadingQuizzes = true
        defer { isLoadingQuizzes = false }

        do {
            await loadQuizTeamMembersIfNeeded()
            matchQuizzes = try await quizService.fetchQuizzesForMatch(matchId: matchId)
            hasLoadedQuizzes = true

            if let quizId = selectedQuizId ?? matchQuizzes.first?.id {
                await loadQuizContext(quizId: quizId)
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

    func loadQuizContext(quizId: String) async {
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

            if detail.resolvedStatus.showsLeaderboard || quizIsExcludedPlayer {
                let leaderboard = try await quizService.fetchLeaderboard(quizId: quizId)
                applyLeaderboardResponse(leaderboard)
            } else {
                applyLeaderboardResponse(nil)
            }
        } catch {
            surfaceError(error)
        }
    }

    func createQuizForMatch() async -> Bool {
        guard quizCanManage else { return false }

        isSubmitting = true
        errorMessage = nil
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

    func saveQuizDraft(title: String, questions: [MatchQuizQuestion]) async -> Bool {
        guard quizCanManage, let quizId = activeQuizDetail?.id else { return false }
        guard questions.count == 10 else {
            errorMessage = L10n.text("quizRulesNotSatisfied")
            return false
        }

        isSubmitting = true
        errorMessage = nil
        defer { isSubmitting = false }

        let locale = quizPatchLocale
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

    func publishQuiz(title: String, questions: [MatchQuizQuestion]) async -> Bool {
        guard quizCanManage, let quizId = activeQuizDetail?.id else { return false }
        guard questions.count == 10,
              questions.allSatisfy(\.hasDefinedAnswer),
              questions.contains(where: { $0.correctAnswer == false }) else {
            errorMessage = L10n.text("quizRulesNotSatisfied")
            return false
        }

        isSubmitting = true
        errorMessage = nil
        defer { isSubmitting = false }

        let locale = quizPatchLocale
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

    func closeQuiz() async -> Bool {
        guard quizCanManage, let quizId = activeQuizDetail?.id else { return false }

        isSubmitting = true
        errorMessage = nil
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

    func deleteQuiz() async -> Bool {
        guard quizCanManage, let quizId = activeQuizDetail?.id else { return false }

        isSubmitting = true
        errorMessage = nil
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

    func submitQuizAnswers(_ answers: [MatchQuizAnswerDraft]) async -> MatchQuizSubmitResult? {
        guard quizCanParticipate,
              let quizId = activeQuizDetail?.id,
              activeQuizDetail?.resolvedStatus.isPlayable == true else {
            return nil
        }

        guard answers.count == activeQuizDetail?.questions.count,
              answers.allSatisfy({ $0.answer != nil }) else {
            errorMessage = L10n.text("quizRulesNotSatisfied")
            return nil
        }

        isSubmitting = true
        errorMessage = nil
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

    func loadQuizTeamMembersIfNeeded() async {
        guard quizTeamMembers.isEmpty,
              let teamId = match?.teamId,
              !teamId.isEmpty else { return }

        do {
            let team = try await teamService.fetchTeam(id: teamId)
            let guests = (try? await teamService.fetchTeamGuests(teamId: teamId)) ?? []
            quizTeamMembers = team.withGuests(guests).resolvedMembers
        } catch {
            quizTeamMembers = []
        }
    }

    func reloadQuizLeaderboardIfNeeded() async {
        guard let quizId = activeQuizDetail?.id, !quizId.isEmpty else { return }
        guard activeQuizDetail?.resolvedStatus.showsLeaderboard == true
            || quizCanManage
            || quizIsExcludedPlayer else { return }

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

    private var quizPatchLocale: String {
        LocalizationManager.shared.language.rawValue
    }
}

private extension String {
    var nilIfWhitespace: String? {
        let trimmed = trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }
}
