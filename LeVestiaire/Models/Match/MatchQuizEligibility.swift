//
//  MatchQuizEligibility.swift
//  LeVestaire
//

import Foundation

enum MatchQuizEligibility {
    static func lineupMemberKeys(from composition: TeamComposition?) -> Set<String> {
        guard let composition else { return [] }

        var keys = Set<String>()
        for assignment in composition.allAssignments {
            guard let memberId = assignment.resolvedMemberId else { continue }
            keys.insert(memberId)
            for variant in CompositionMemberKey.variants(for: memberId) {
                keys.insert(variant)
            }
        }
        return keys
    }

    static func isUserInMatchLineup(
        userId: String?,
        teamMembers: [TeamMember],
        composition: TeamComposition?
    ) -> Bool {
        guard let userId, !userId.isEmpty else { return false }

        let lineupKeys = lineupMemberKeys(from: composition)
        guard !lineupKeys.isEmpty else { return false }

        guard let member = teamMembers.first(where: { ($0.userId ?? $0.id) == userId }) else {
            return false
        }

        let memberKey = member.compositionMemberKey
        if lineupKeys.contains(memberKey) { return true }

        for variant in CompositionMemberKey.variants(for: memberKey) {
            if lineupKeys.contains(variant) { return true }
        }

        return false
    }

    static func canParticipate(
        userId: String?,
        eligibleUserIds: [String],
        teamMembers: [TeamMember],
        composition: TeamComposition?
    ) -> Bool {
        guard let userId, !userId.isEmpty else { return false }

        if !eligibleUserIds.isEmpty {
            return eligibleUserIds.contains(userId)
        }

        guard !teamMembers.isEmpty else { return false }
        guard teamMembers.contains(where: { ($0.userId ?? $0.id) == userId }) else { return false }
        return !isUserInMatchLineup(
            userId: userId,
            teamMembers: teamMembers,
            composition: composition
        )
    }

    static func isExcludedFromQuiz(
        userId: String?,
        eligibleUserIds: [String],
        teamMembers: [TeamMember],
        composition: TeamComposition?
    ) -> Bool {
        guard let userId, !userId.isEmpty else { return false }

        if !eligibleUserIds.isEmpty {
            guard !eligibleUserIds.contains(userId) else { return false }
            if teamMembers.contains(where: { ($0.userId ?? $0.id) == userId }) {
                return true
            }
            return isUserInMatchLineup(
                userId: userId,
                teamMembers: teamMembers,
                composition: composition
            )
        }

        return isUserInMatchLineup(
            userId: userId,
            teamMembers: teamMembers,
            composition: composition
        )
    }
}
