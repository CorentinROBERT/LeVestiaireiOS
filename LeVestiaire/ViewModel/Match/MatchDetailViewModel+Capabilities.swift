//
//  MatchDetailViewModel+Capabilities.swift
//  LeVestaire
//

import Foundation

extension MatchDetailViewModel {
    var uxMode: MatchUXMode {
        match?.uxMode ?? .readOnly
    }

    var showsRespondSection: Bool {
        match?.capabilities.canRespond == true
    }

    var showsPrepareHub: Bool {
        match?.showsPrepareHub ?? false
    }

    var tabConfiguration: MatchDetailTabConfiguration? {
        guard let match else { return nil }
        return MatchDetailTabConfiguration.forMatch(match, showsPrepareHub: showsPrepareHub)
    }

    var publishButtonEnabled: Bool {
        match?.canPublishMatch ?? false
    }

    var publishBlockerMessages: [String] {
        match?.effectivePublishBlockers.map(\.localizedMessage) ?? []
    }

    var eventPlayerOptions: [MatchEventPlayerOption] {
        compositionDisplayMembers.compactMap { member in
            let memberKey = member.compositionMemberKey
            guard !memberKey.isEmpty else { return nil }
            return MatchEventPlayerOption(id: memberKey, name: member.displayName)
        }
    }

    var editorMembers: [TeamMember] {
        if match?.composition != nil {
            return compositionDisplayMembers
        }

        return compositionPlayerPool
    }

    var compositionPlayerPool: [TeamMember] {
        if !compositionViewModel.selectablePlayers.isEmpty {
            return compositionViewModel.selectablePlayers.map { $0.asTeamMember() }
        }

        if !availabilityViewModel.availability.isEmpty {
            return availabilityViewModel.availability.map { $0.asSelectablePlayer().asTeamMember() }
        }

        return []
    }

    var compositionDisplayMembers: [TeamMember] {
        guard let composition = match?.composition else { return compositionPlayerPool }

        let assignments = composition.allAssignments
        let pool = compositionPlayerPool
        var seen = Set<String>()

        return assignments.compactMap { assignment in
            guard let memberId = assignment.resolvedMemberId, !seen.contains(memberId) else {
                return nil
            }
            seen.insert(memberId)

            if let pooledMember = pool.first(where: { $0.matchesCompositionMemberKey(memberId) }) {
                return pooledMember
            }

            let isGuest = CompositionMemberKey.isGuestKey(memberId)
            return TeamMember(
                id: isGuest ? CompositionMemberKey.rawGuestId(from: memberId) : memberId,
                userId: isGuest ? nil : memberId,
                firstName: assignment.firstName,
                lastName: assignment.lastName,
                isGuest: isGuest
            )
        }
    }

    var canEditComposition: Bool {
        compositionViewModel.canEdit
    }

    var canEditMatchInfo: Bool {
        guard let match else { return false }
        return match.status.isPreparationStatus
            && !match.isPreparationLocked
            && (
                match.capabilities.canPublish
                    || match.capabilities.canManageAvailability
                    || match.capabilities.canManageComposition
            )
    }

    var canManageMatchLifecycle: Bool {
        guard let match else { return false }
        return match.status.isPreparationStatus && match.capabilities.canPublish
    }

    var showsAvailabilityManagement: Bool {
        guard let match else { return false }
        if match.capabilities.canManageAvailability {
            return true
        }
        return canManageMatchTeam && match.status.isPreparationStatus
    }

    var canManageMatchEvents: Bool {
        eventsViewModel.canManage
    }
}
