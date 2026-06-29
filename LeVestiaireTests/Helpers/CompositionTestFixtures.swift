//
//  CompositionTestFixtures.swift
//  LeVestiaireTests
//

import Foundation
@testable import LeVestiaire

enum CompositionTestFixtures {
    static let alice = TeamMember(
        id: "member-1",
        userId: "user-1",
        firstName: "Alice",
        lastName: "Martin",
        jerseyNumber: 1
    )

    static let bob = TeamMember(
        id: "member-2",
        userId: "user-2",
        firstName: "Bob",
        lastName: "Bernard",
        jerseyNumber: 7
    )

    static let guest = TeamMember(
        id: "guest-1",
        firstName: "Invité",
        lastName: "Test",
        jerseyNumber: 99,
        isGuest: true
    )

    static func tab(
        starters: [String: String] = [:],
        substitutes: [String?] = Array(repeating: nil, count: CompositionTabDraft.substituteCount),
        captainMemberKey: String? = nil
    ) -> CompositionTabDraft {
        CompositionTabDraft(
            starterAssignments: starters,
            substituteMemberIds: substitutes,
            captainMemberKey: captainMemberKey
        )
    }

    static func availability(
        for member: TeamMember,
        status: MatchAvailabilityStatus
    ) -> MatchAvailabilityEntry {
        MatchAvailabilityEntry(
            playerId: member.id,
            userId: member.userId,
            memberId: member.id,
            firstName: member.firstName,
            lastName: member.lastName,
            status: status
        )
    }

    static func sevenStarterMembers() -> [TeamMember] {
        (1...7).map { index in
            TeamMember(
                id: "member-\(index)",
                userId: "user-\(index)",
                firstName: "Player",
                lastName: "\(index)",
                jerseyNumber: index
            )
        }
    }

    static func selectablePlayers(from members: [TeamMember]) -> [MatchSelectablePlayer] {
        members.map {
            MatchSelectablePlayer(
                id: $0.id,
                userId: $0.userId,
                firstName: $0.firstName,
                lastName: $0.lastName,
                isGuest: $0.isGuest
            )
        }
    }

    static func fullStarterTab(
        name: String = "Titulaires",
        members: [TeamMember] = sevenStarterMembers()
    ) -> CompositionTabDraft {
        let slots = ["GK", "D1", "D2", "D3", "M1", "M2", "A1"]
        var starters: [String: String] = [:]
        for (slot, member) in zip(slots, members) {
            starters[slot] = member.compositionMemberKey
        }
        return CompositionTabDraft(
            name: name,
            starterAssignments: starters,
            isMain: true
        )
    }
}
