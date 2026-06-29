//
//  CompositionEditorEngineTests.swift
//  LeVestiaireTests
//

import Testing
@testable import LeVestiaire

struct CompositionEditorEngineTests {
    private let alice = CompositionTestFixtures.alice
    private let bob = CompositionTestFixtures.bob
    private let guest = CompositionTestFixtures.guest

    @Test
    func assignedMemberIds_excludesCurrentSlot() {
        let tab = CompositionTestFixtures.tab(
            starters: ["GK": alice.compositionMemberKey],
            substitutes: [bob.compositionMemberKey, nil, nil, nil]
        )
        let context = CompositionPickerContext(positionId: "GK", substituteIndex: nil)

        let assigned = CompositionEditorEngine.assignedMemberIds(in: tab, excluding: context)

        #expect(!assigned.contains(alice.compositionMemberKey))
        #expect(assigned.contains(bob.compositionMemberKey))
    }

    @Test
    func applySelection_movesMemberToStarterAndClearsPreviousSlot() {
        var tab = CompositionTestFixtures.tab(
            starters: ["GK": alice.compositionMemberKey],
            substitutes: [bob.compositionMemberKey, nil, nil, nil]
        )
        let context = CompositionPickerContext(positionId: "ST", substituteIndex: nil)

        CompositionEditorEngine.applySelection(member: bob, context: context, to: &tab)

        #expect(tab.starterAssignments["ST"] == bob.compositionMemberKey)
        #expect(tab.substituteMemberIds[0] == nil)
        #expect(tab.memberJerseyNumbers[bob.compositionMemberKey] == 7)
    }

    @Test
    func clearSelection_removesStarterAndCaptain() {
        var tab = CompositionTestFixtures.tab(
            starters: ["GK": alice.compositionMemberKey],
            captainMemberKey: alice.compositionMemberKey
        )
        let context = CompositionPickerContext(positionId: "GK", substituteIndex: nil)

        CompositionEditorEngine.clearSelection(context: context, in: &tab)

        #expect(tab.starterAssignments["GK"] == nil)
        #expect(tab.captainMemberKey == nil)
    }

    @Test
    func slotOccupant_returnsMatchingMember() {
        let tab = CompositionTestFixtures.tab(starters: ["GK": alice.compositionMemberKey])
        let context = CompositionPickerContext(positionId: "GK", substituteIndex: nil)
        let members = [alice, bob]

        let occupant = CompositionEditorEngine.slotOccupant(for: context, in: tab, members: members)

        #expect(occupant == alice)
    }

    @Test
    func templateAvailabilityReview_flagsAbsentAndUnknownMembers() {
        let tab = CompositionTestFixtures.tab(
            starters: [
                "GK": alice.compositionMemberKey,
                "ST": bob.compositionMemberKey,
            ]
        )
        let availability = [
            CompositionTestFixtures.availability(for: alice, status: .absent),
            CompositionTestFixtures.availability(for: bob, status: .unknown),
        ]

        let review = CompositionEditorEngine.templateAvailabilityReview(
            tab: tab,
            members: [alice, bob],
            availability: availability
        )

        #expect(review.absent == [alice])
        #expect(review.unknown == [bob])
        #expect(review.hasConflicts)
        #expect(review.absentNames == "Alice Martin")
        #expect(review.unknownNames == "Bob Bernard")
    }

    @Test
    func templateAvailabilityReview_ignoresGuestsAndEmptyAvailability() {
        let tab = CompositionTestFixtures.tab(
            starters: ["GK": guest.compositionMemberKey]
        )

        let reviewWithGuest = CompositionEditorEngine.templateAvailabilityReview(
            tab: tab,
            members: [guest],
            availability: [
                MatchAvailabilityEntry(playerId: "guest-1", status: .absent),
            ]
        )
        #expect(reviewWithGuest.absent.isEmpty)
        #expect(reviewWithGuest.unknown.isEmpty)

        let reviewWithoutAvailability = CompositionEditorEngine.templateAvailabilityReview(
            tab: tab,
            members: [guest],
            availability: []
        )
        #expect(!reviewWithoutAvailability.hasConflicts)
    }

    @Test
    func removeAbsentMembers_clearsAbsentPlayersFromTab() {
        var tab = CompositionTestFixtures.tab(
            starters: [
                "GK": alice.compositionMemberKey,
                "ST": bob.compositionMemberKey,
            ],
            substitutes: [nil, nil, nil, nil],
            captainMemberKey: alice.compositionMemberKey
        )
        let availability = [
            CompositionTestFixtures.availability(for: alice, status: .absent),
            CompositionTestFixtures.availability(for: bob, status: .available),
        ]

        CompositionEditorEngine.removeAbsentMembers(
            from: &tab,
            members: [alice, bob],
            availability: availability
        )

        #expect(tab.starterAssignments["GK"] == nil)
        #expect(tab.starterAssignments["ST"] == bob.compositionMemberKey)
        #expect(tab.captainMemberKey == nil)
    }
}
