//
//  MatchDecodingTests.swift
//  LeVestiaireTests
//

import Foundation
import Testing
@testable import LeVestiaire

struct MatchDecodingTests {

    @Test
    func decodeAvailabilityList_supportsDirectArray() throws {
        let data = Data("""
        [
          {"playerId":"p1","userId":"u1","status":"available"},
          {"playerId":"","userId":"u2","status":"absent"}
        ]
        """.utf8)

        let entries = try MatchDecoding.decodeAvailabilityList(from: data)

        #expect(entries.count == 2)
        #expect(entries[0].playerId == "u1")
        #expect(entries[0].status == .available)
        #expect(entries[1].playerId == "u2")
        #expect(entries[1].status == .absent)
    }

    @Test
    func decodeAvailabilityList_filtersEntriesWithoutResolvableId() throws {
        let data = Data("""
        [
          {"playerId":"","status":"available"}
        ]
        """.utf8)

        let entries = try MatchDecoding.decodeAvailabilityList(from: data)

        #expect(entries.isEmpty)
    }

    @Test
    func decodeAvailabilityList_supportsDataEnvelopeAndPayloadKeys() throws {
        let enveloped = Data("""
        {
          "data": [
            {"playerId":"p1","userId":"u1","status":"available"}
          ]
        }
        """.utf8)
        let payload = Data("""
        {
          "data": {
            "players": [
              {"playerId":"p2","userId":"u2","status":"unknown"}
            ]
          }
        }
        """.utf8)

        let envelopedEntries = try MatchDecoding.decodeAvailabilityList(from: enveloped)
        let payloadEntries = try MatchDecoding.decodeAvailabilityList(from: payload)

        #expect(envelopedEntries.map(\.playerId) == ["u1"])
        #expect(payloadEntries.map(\.playerId) == ["u2"])
        #expect(payloadEntries[0].status == .unknown)
    }

    @Test
    func decodeAvailabilityList_returnsEmptyArrayForUnknownShape() throws {
        let data = Data("{}".utf8)
        #expect(try MatchDecoding.decodeAvailabilityList(from: data).isEmpty)
    }

    @Test
    func decodePresentMembers_sortsAndFiltersEmptyIds() throws {
        let data = Data("""
        [
          {"id":"m2","firstName":"Zoe","lastName":"Zen"},
          {"id":"","firstName":"Hidden"},
          {"id":"m1","firstName":"Alice","lastName":"A"}
        ]
        """.utf8)

        let members = try MatchDecoding.decodePresentMembers(from: data)

        #expect(members.map(\.id) == ["m1", "m2"])
        #expect(members[0].displayName == "Alice A")
    }

    @Test
    func decodePresentMembers_supportsWrappedPayloadKeys() throws {
        let data = Data("""
        {
          "data": {
            "present": [
              {"id":"m1","firstName":"Alice","lastName":"A"}
            ]
          }
        }
        """.utf8)

        let members = try MatchDecoding.decodePresentMembers(from: data)

        #expect(members.count == 1)
        #expect(members[0].id == "m1")
    }

    @Test
    func decodeSelectablePlayers_mergesMembersAndGuests() throws {
        let data = Data("""
        {
          "data": {
            "members": [{"id":"m1","firstName":"Alice"}],
            "guests": [{"id":"g1","firstName":"Guest"}]
          }
        }
        """.utf8)

        let players = try MatchDecoding.decodeSelectablePlayers(from: data)

        #expect(players.map(\.id) == ["m1", "g1"])
    }

    @Test
    func decodeEvents_filtersInactiveEvents() throws {
        let data = Data("""
        [
          {"id":"e1","type":"goal","isActive":true},
          {"id":"e2","type":"goal","isActive":false},
          {"id":"e3","type":"yellow_card","isActive":true}
        ]
        """.utf8)

        let events = try MatchDecoding.decodeEvents(from: data)

        #expect(events.map(\.id) == ["e1", "e3"])
    }

    @Test(arguments: [
        ("missing_minimal_info", "missingMinimalInfo"),
        ("hello_world", "helloWorld"),
        ("single", "single"),
    ])
    func snakeCaseToLowerCamel_convertsIdentifiers(input: String, expected: String) {
        #expect(input.snakeCaseToLowerCamel() == expected)
    }
}
