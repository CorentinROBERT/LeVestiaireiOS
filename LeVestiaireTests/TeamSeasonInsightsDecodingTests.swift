//
//  TeamSeasonInsightsDecodingTests.swift
//  LeVestiaireTests
//

import Foundation
import Testing
@testable import LeVestiaire

struct TeamSeasonInsightsDecodingTests {

    @Test
    func decodeTeamSeasonInsights_mapsFormLast5ToResults() throws {
        let data = Data(
            """
            {
              "success": true,
              "data": {
                "teamId": "674abc123def456789012345",
                "season": "2024-2025",
                "form": {
                  "last5": ["W", "D", "D", "L", "W"],
                  "points": 7,
                  "goalsFor": 9,
                  "goalsAgainst": 4
                },
                "streak": { "type": "win", "count": 1 }
              }
            }
            """.utf8
        )

        let payload = try APIResponseDecoder.decodePayload(TeamSeasonInsightsPayload.self, from: data)

        #expect(payload.form?.results.map(\.shortLabel) == ["V", "N", "N", "D", "V"])
        #expect(payload.form?.points == 7)
        #expect(payload.form?.goalsFor == 9)
        #expect(payload.form?.goalsAgainst == 4)
        #expect(payload.form?.hasContent == true)
    }
}
