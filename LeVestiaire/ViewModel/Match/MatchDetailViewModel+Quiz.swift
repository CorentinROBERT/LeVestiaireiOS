//
//  MatchDetailViewModel+Quiz.swift
//  LeVestaire
//

import Foundation

extension MatchDetailViewModel {
    func loadQuizzesIfNeeded(force: Bool = false) async {
        guard let match else { return }
        guard match.status == .finished else { return }
        guard force || !hasLoadedQuizzes else { return }

        isLoadingQuizzes = true
        defer { isLoadingQuizzes = false }

        do {
            matchQuizzes = try await matchService.fetchQuizzesForMatch(matchId: matchId)
            hasLoadedQuizzes = true
        } catch {
            if isCancellationError(error) { return }
            matchQuizzes = []
            surfaceError(error)
        }
    }
}
