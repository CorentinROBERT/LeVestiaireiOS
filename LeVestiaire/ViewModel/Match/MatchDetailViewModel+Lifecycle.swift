//
//  MatchDetailViewModel+Lifecycle.swift
//  LeVestaire
//

import Foundation

extension MatchDetailViewModel {
    func updateMatchInfo(from updatedMatch: MatchDetail) {
        applyMatchUpdate(updatedMatch)
    }

    func cancelMatch() async -> Bool {
        guard canManageMatchLifecycle else { return false }
        return await updateStatus(.cancelled)
    }

    func postponeMatch() async -> Bool {
        guard canManageMatchLifecycle else { return false }
        return await updateStatus(.postponed)
    }

    func publishMatch() async -> Bool {
        guard match?.canPublishMatch == true else { return false }

        isSubmitting = true
        errorMessage = nil
        defer { isSubmitting = false }

        do {
            match = try await matchService.publishMatch(id: matchId)
            await loadSupplementaryData()
            return true
        } catch {
            surfaceError(error)
            return false
        }
    }

    func startMatch() async -> Bool {
        guard match?.capabilities.canStartMatch == true else { return false }
        return await updateStatus(.ongoing)
    }

    func finishMatch() async -> Bool {
        guard match?.capabilities.canFinishMatch == true else { return false }
        return await updateStatus(.finished)
    }

    func updateScore(home: Int, away: Int) async -> Bool {
        guard match?.capabilities.canUpdateScore == true else { return false }

        isSubmitting = true
        errorMessage = nil
        defer { isSubmitting = false }

        do {
            match = try await matchService.updateScore(
                matchId: matchId,
                scoreHome: home,
                scoreAway: away
            )
            return true
        } catch {
            surfaceError(error)
            return false
        }
    }

    func updateStatus(_ status: MatchStatus) async -> Bool {
        isSubmitting = true
        errorMessage = nil
        defer { isSubmitting = false }

        do {
            match = try await matchService.updateMatchStatus(id: matchId, status: status)
            await loadSupplementaryData()
            return true
        } catch {
            surfaceError(error)
            return false
        }
    }
}
