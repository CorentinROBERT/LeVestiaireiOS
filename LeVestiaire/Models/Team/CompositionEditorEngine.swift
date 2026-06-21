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
            tab.starterAssignments.removeValue(forKey: positionId)
        } else if let substituteIndex = context.substituteIndex {
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
            }
        }

        for substituteIndex in tab.substituteMemberIds.indices {
            guard substituteIndex != excludingSubstituteIndex else { continue }
            guard let assignedKey = tab.substituteMemberIds[substituteIndex] else { continue }
            if member.matchesCompositionMemberKey(assignedKey) {
                tab.substituteMemberIds[substituteIndex] = nil
            }
        }
    }
}
