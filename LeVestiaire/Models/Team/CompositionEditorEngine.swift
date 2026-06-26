//
//  CompositionEditorEngine.swift
//  LeVestaire
//

import Foundation

struct CompositionPickerContext: Identifiable, Equatable {
    let id = UUID()
    let positionId: String?
    let substituteIndex: Int?
}

enum CompositionEditorEngine {
    static func assignedMemberIds(
        in tab: CompositionTabDraft,
        excluding context: CompositionPickerContext
    ) -> Set<String> {
        var ids = Set<String>()
        ids.formUnion(tab.starterAssignments.values)
        ids.formUnion(tab.substituteMemberIds.compactMap { $0 })

        if let positionId = context.positionId,
           let current = tab.starterAssignments[positionId] {
            ids.remove(current)
        }

        if let substituteIndex = context.substituteIndex,
           let current = tab.substituteMemberIds[substituteIndex] {
            ids.remove(current)
        }

        return ids
    }

    static func applySelection(
        member: TeamMember,
        context: CompositionPickerContext,
        to tab: inout CompositionTabDraft
    ) {
        let memberKey = member.compositionMemberKey

        clearMemberFromTab(
            member: member,
            in: &tab,
            excludingPositionId: context.positionId,
            excludingSubstituteIndex: context.substituteIndex
        )

        if let positionId = context.positionId {
            tab.starterAssignments[positionId] = memberKey
        } else if let substituteIndex = context.substituteIndex {
            tab.substituteMemberIds[substituteIndex] = memberKey
        }

        if let jerseyNumber = member.jerseyNumber {
            tab.memberJerseyNumbers[memberKey] = jerseyNumber
        }
    }

    static func clearSelection(
        context: CompositionPickerContext,
        in tab: inout CompositionTabDraft
    ) {
        if let positionId = context.positionId {
            if let removedKey = tab.starterAssignments[positionId] {
                clearCaptainIfNeeded(memberKey: removedKey, in: &tab)
            }
            tab.starterAssignments.removeValue(forKey: positionId)
        } else if let substituteIndex = context.substituteIndex {
            if let removedKey = tab.substituteMemberIds[substituteIndex] {
                clearCaptainIfNeeded(memberKey: removedKey, in: &tab)
            }
            tab.substituteMemberIds[substituteIndex] = nil
        }
    }

    static func slotOccupant(
        for context: CompositionPickerContext,
        in tab: CompositionTabDraft,
        members: [TeamMember]
    ) -> TeamMember? {
        let memberKey: String?
        if let positionId = context.positionId {
            memberKey = tab.starterAssignments[positionId]
        } else if let substituteIndex = context.substituteIndex {
            memberKey = tab.substituteMemberIds[substituteIndex]
        } else {
            memberKey = nil
        }

        guard let memberKey else { return nil }
        return members.first { $0.matchesCompositionMemberKey(memberKey) }
    }

    static func clearMemberFromTab(
        member: TeamMember,
        in tab: inout CompositionTabDraft,
        excludingPositionId: String? = nil,
        excludingSubstituteIndex: Int? = nil
    ) {
        for (positionId, assignedKey) in tab.starterAssignments {
            guard positionId != excludingPositionId else { continue }
            if member.matchesCompositionMemberKey(assignedKey) {
                tab.starterAssignments.removeValue(forKey: positionId)
                clearCaptainIfNeeded(member: member, in: &tab)
            }
        }

        for substituteIndex in tab.substituteMemberIds.indices {
            guard substituteIndex != excludingSubstituteIndex else { continue }
            guard let assignedKey = tab.substituteMemberIds[substituteIndex] else { continue }
            if member.matchesCompositionMemberKey(assignedKey) {
                tab.substituteMemberIds[substituteIndex] = nil
                clearCaptainIfNeeded(member: member, in: &tab)
            }
        }
    }

    private static func clearCaptainIfNeeded(member: TeamMember, in tab: inout CompositionTabDraft) {
        guard let captainKey = tab.captainMemberKey,
              member.matchesCompositionMemberKey(captainKey) else { return }
        tab.captainMemberKey = nil
    }

    private static func clearCaptainIfNeeded(memberKey: String, in tab: inout CompositionTabDraft) {
        guard let captainKey = tab.captainMemberKey else { return }
        if CompositionMemberKey.variants(for: captainKey).contains(memberKey) {
            tab.captainMemberKey = nil
        }
    }

    static func availabilityStatus(
        for member: TeamMember,
        in availability: [MatchAvailabilityEntry]
    ) -> MatchAvailabilityStatus? {
        guard !member.isGuest else { return nil }
        return availability.first(where: { $0.matchesMember(member) })?.status
    }

    static func templateAvailabilityReview(
        tab: CompositionTabDraft,
        members: [TeamMember],
        availability: [MatchAvailabilityEntry]
    ) -> CompositionTemplateAvailabilityReview {
        templateAvailabilityReview(
            tabs: [tab],
            members: members,
            availability: availability
        )
    }

    static func templateAvailabilityReview(
        tabs: [CompositionTabDraft],
        members: [TeamMember],
        availability: [MatchAvailabilityEntry]
    ) -> CompositionTemplateAvailabilityReview {
        guard !availability.isEmpty else {
            return CompositionTemplateAvailabilityReview()
        }

        var absent: [TeamMember] = []
        var unknown: [TeamMember] = []
        var seenMemberIds = Set<String>()

        let assignedKeys = Set(
            tabs.flatMap { tab in
                tab.starterAssignments.values + tab.substituteMemberIds.compactMap { $0 }
            }
        )

        for memberKey in assignedKeys {
            guard let member = members.first(where: { $0.matchesCompositionMemberKey(memberKey) }) else {
                continue
            }
            guard !member.isGuest else { continue }
            guard seenMemberIds.insert(member.id).inserted else { continue }

            switch availabilityStatus(for: member, in: availability) ?? .unknown {
            case .absent:
                absent.append(member)
            case .unknown:
                unknown.append(member)
            case .available:
                break
            }
        }

        let sort: (TeamMember, TeamMember) -> Bool = {
            $0.displayName.localizedCaseInsensitiveCompare($1.displayName) == .orderedAscending
        }

        return CompositionTemplateAvailabilityReview(
            absent: absent.sorted(by: sort),
            unknown: unknown.sorted(by: sort)
        )
    }

    static func removeAbsentMembers(
        from tab: inout CompositionTabDraft,
        members: [TeamMember],
        availability: [MatchAvailabilityEntry]
    ) {
        let review = templateAvailabilityReview(tab: tab, members: members, availability: availability)
        for member in review.absent {
            clearMemberFromTab(member: member, in: &tab)
        }
    }

    static func removeAbsentMembers(
        from tabs: inout [CompositionTabDraft],
        members: [TeamMember],
        availability: [MatchAvailabilityEntry]
    ) {
        for index in tabs.indices {
            removeAbsentMembers(from: &tabs[index], members: members, availability: availability)
        }
    }
}

struct CompositionTemplateAvailabilityReview: Equatable {
    let absent: [TeamMember]
    let unknown: [TeamMember]

    init(absent: [TeamMember] = [], unknown: [TeamMember] = []) {
        self.absent = absent
        self.unknown = unknown
    }

    var hasConflicts: Bool {
        !absent.isEmpty || !unknown.isEmpty
    }

    var absentNames: String {
        absent.map(\.displayName).joined(separator: ", ")
    }

    var unknownNames: String {
        unknown.map(\.displayName).joined(separator: ", ")
    }
}
