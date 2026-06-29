//
//  CompositionMemberKeyTests.swift
//  LeVestiaireTests
//

import Testing
@testable import LeVestiaire

struct CompositionMemberKeyTests {

    @Test
    func forGuest_prefixesRawId() {
        #expect(CompositionMemberKey.forGuest("abc") == "guest_abc")
        #expect(CompositionMemberKey.forGuest("guest_abc") == "guest_abc")
        #expect(CompositionMemberKey.forGuest("") == "")
    }

    @Test
    func variants_includesGuestAndRawForms() {
        let guestVariants = CompositionMemberKey.variants(for: "guest_42")
        #expect(guestVariants.contains("guest_42"))
        #expect(guestVariants.contains("42"))

        let userVariants = CompositionMemberKey.variants(for: "user-1")
        #expect(userVariants.contains("user-1"))
        #expect(userVariants.contains("guest_user-1"))
    }

    @Test
    func teamMember_matchesCompositionKeysAcrossVariants() {
        let member = CompositionTestFixtures.alice

        #expect(member.matchesCompositionMemberKey("user-1"))
        #expect(member.matchesCompositionMemberKey("member-1"))
        #expect(!member.matchesCompositionMemberKey("other-user"))
    }
}
