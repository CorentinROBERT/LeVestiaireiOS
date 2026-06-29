//
//  DeepLinkParserTests.swift
//  LeVestiaireTests
//

import Foundation
import Testing
@testable import LeVestiaire

struct DeepLinkParserTests {

    @Test(arguments: [
        ("https://join?code=TEAM01", "TEAM01"),
        ("https://example.com/join?code=abc123", "abc123"),
        ("https://example.com/teams/join?code=XYZ9", "XYZ9"),
        ("https://app.squad-locker.com?code=UNIV01", "UNIV01"),
        ("https://join?code=%20TEAM02%20", "TEAM02"),
    ])
    func teamInviteCode_parsesValidURLs(urlString: String, expectedCode: String) throws {
        let url = try #require(URL(string: urlString))
        #expect(DeepLinkParser.teamInviteCode(from: url) == expectedCode)
    }

    @Test(arguments: [
        "https://example.com/home?code=TEAM01",
        "https://join",
        "https://example.com/join",
        "https://join?code=",
        "https://join?code=%20%20",
    ])
    func teamInviteCode_returnsNilForInvalidURLs(urlString: String) throws {
        let url = try #require(URL(string: urlString))
        #expect(DeepLinkParser.teamInviteCode(from: url) == nil)
    }
}
