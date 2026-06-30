//
//  TeamSeasonDuosDecodingTests.swift
//  LeVestiaireTests
//

import Foundation
import Testing
@testable import LeVestiaire

struct TeamSeasonDuosDecodingTests {

    @Test
    func decodeTeamSeasonDuos_usesPairKeyAndMongoPlayerIds() throws {
        let data = Data(
            """
            {
              "success": true,
              "data": {
                "teamId": "674abc123def456789012345",
                "season": "2024-2025",
                "duos": [
                  {
                    "pairKey": "64f1a2b3c4d5e6f7a8b9c0d1|64f1a2b3c4d5e6f7a8b9c0d2",
                    "playerA": {
                      "_id": "64f1a2b3c4d5e6f7a8b9c0d1",
                      "firstName": "Jean",
                      "lastName": "Dupont"
                    },
                    "playerB": {
                      "_id": "64f1a2b3c4d5e6f7a8b9c0d2",
                      "firstName": "Paul",
                      "lastName": "Martin"
                    },
                    "goalsTogether": 3,
                    "totalCombos": 3
                  },
                  {
                    "pairKey": "507f1f77bcf86cd799439099|64f1a2b3c4d5e6f7a8b9c0d2",
                    "playerA": {
                      "_id": "507f1f77bcf86cd799439099",
                      "firstName": "Invité",
                      "lastName": "Test",
                      "isGuest": true
                    },
                    "playerB": {
                      "_id": "64f1a2b3c4d5e6f7a8b9c0d2",
                      "firstName": "Paul",
                      "lastName": "Martin"
                    },
                    "goalsTogether": 1,
                    "totalCombos": 1
                  }
                ]
              }
            }
            """.utf8
        )

        let payload = try APIResponseDecoder.decodePayload(TeamSeasonDuosPayload.self, from: data)

        #expect(payload.duos.count == 2)
        #expect(payload.duos[0].pairKey == "64f1a2b3c4d5e6f7a8b9c0d1|64f1a2b3c4d5e6f7a8b9c0d2")
        #expect(payload.duos[0].id == payload.duos[0].pairKey)
        #expect(payload.duos[0].playerA.id == "64f1a2b3c4d5e6f7a8b9c0d1")
        #expect(payload.duos[0].playerB.id == "64f1a2b3c4d5e6f7a8b9c0d2")
        #expect(payload.duos[1].playerA.displayName == "Invité Test")
        #expect(Set(payload.duos.map(\.id)).count == payload.duos.count)
    }
}
