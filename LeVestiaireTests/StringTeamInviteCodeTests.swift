//
//  StringTeamInviteCodeTests.swift
//  LeVestiaireTests
//

import Testing
@testable import LeVestiaire

struct StringTeamInviteCodeTests {

    @Test(arguments: [
        (" team01 ", "TEAM01"),
        ("AbCd", "ABCD"),
        ("CODE-12", "CODE-12"),
    ])
    func normalizedTeamInviteCode_trimsAndUppercases(input: String, expected: String) {
        #expect(input.normalizedTeamInviteCode == expected)
    }

    @Test(arguments: [
        "ABCD",
        "team-01",
        "A_B_C",
        String(repeating: "A", count: 24),
    ])
    func isLikelyTeamInviteCode_acceptsValidTokens(_ value: String) {
        #expect(value.isLikelyTeamInviteCode)
    }

    @Test(arguments: [
        "ABC",
        String(repeating: "A", count: 25),
        "TE AM",
        "team@01",
        "nom d'équipe",
    ])
    func isLikelyTeamInviteCode_rejectsInvalidTokens(_ value: String) {
        #expect(!value.isLikelyTeamInviteCode)
    }

    @Test(arguments: [
        ("", ""),
        ("   ", ""),
        (" team01 ", "TEAM01"),
        (" Les Bleus ", "Les Bleus"),
    ])
    func resolvedTeamSearchQuery(input: String, expected: String) {
        #expect(input.resolvedTeamSearchQuery == expected)
    }
}
