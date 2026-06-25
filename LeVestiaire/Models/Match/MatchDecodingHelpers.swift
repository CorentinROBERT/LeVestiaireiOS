//
//  MatchDecodingHelpers.swift
//  LeVestaire
//

import Foundation

// MARK: - Decoding helpers

enum MatchDecoding {
    private struct AvailabilityListPayload: Decodable {
        let availability: [MatchAvailabilityEntry]?
        let items: [MatchAvailabilityEntry]?
        let players: [MatchAvailabilityEntry]?
        let entries: [MatchAvailabilityEntry]?
    }

    private struct PresentMembersPayload: Decodable {
        let members: [MatchPresentMember]?
        let players: [MatchPresentMember]?
        let present: [MatchPresentMember]?
    }

    static func decodeDetail(from data: Data) throws -> MatchDetail {
        if let detail = try? APIResponseDecoder.decodePayload(MatchDetail.self, from: data) {
            return detail
        }
        return try APIResponseDecoder.decode(MatchDetail.self, from: data)
    }

    static func decodeAvailabilityRoster(from data: Data) throws -> MatchAvailabilityRoster {
        if let roster = try? APIResponseDecoder.decodePayload(MatchAvailabilityRoster.self, from: data) {
            return roster
        }
        return try APIResponseDecoder.decode(MatchAvailabilityRoster.self, from: data)
    }

    static func decodeAvailabilityList(from data: Data) throws -> [MatchAvailabilityEntry] {
        if let entries = try? APIResponseDecoder.decodePayload([MatchAvailabilityEntry].self, from: data) {
            return entries.filter { !$0.playerId.isEmpty }
        }
        if let entries = try? APIResponseDecoder.decode([MatchAvailabilityEntry].self, from: data) {
            return entries.filter { !$0.playerId.isEmpty }
        }

        if let payload = try? APIResponseDecoder.decodePayload(AvailabilityListPayload.self, from: data) {
            return mergedAvailability(from: payload)
        }

        if let payload = try? JSONDecoder().decode(AvailabilityListPayload.self, from: data) {
            return mergedAvailability(from: payload)
        }

        return []
    }

    static func decodePresentMembers(from data: Data) throws -> [MatchPresentMember] {
        if let members = try? APIResponseDecoder.decodePayload([MatchPresentMember].self, from: data) {
            return sortedPresentMembers(members)
        }
        if let members = try? APIResponseDecoder.decode([MatchPresentMember].self, from: data) {
            return sortedPresentMembers(members)
        }

        if let payload = try? APIResponseDecoder.decodePayload(PresentMembersPayload.self, from: data) {
            return sortedPresentMembers(mergedPresentMembers(from: payload))
        }

        if let payload = try? JSONDecoder().decode(PresentMembersPayload.self, from: data) {
            return sortedPresentMembers(mergedPresentMembers(from: payload))
        }

        return []
    }

    private static func mergedPresentMembers(from payload: PresentMembersPayload) -> [MatchPresentMember] {
        payload.members ?? payload.present ?? payload.players ?? []
    }

    private static func sortedPresentMembers(_ members: [MatchPresentMember]) -> [MatchPresentMember] {
        members
            .filter { !$0.id.isEmpty }
            .sorted { lhs, rhs in
                lhs.displayName.localizedCaseInsensitiveCompare(rhs.displayName) == .orderedAscending
            }
    }

    private static func mergedAvailability(from payload: AvailabilityListPayload) -> [MatchAvailabilityEntry] {
        let entries = payload.players
            ?? payload.availability
            ?? payload.items
            ?? payload.entries
            ?? []
        return entries.filter { !$0.playerId.isEmpty }
    }

    static func decodeSelectablePlayers(from data: Data) throws -> [MatchSelectablePlayer] {
        if let players = try? APIResponseDecoder.decodePayload([MatchSelectablePlayer].self, from: data) {
            return players.filter { !$0.id.isEmpty }
        }
        if let players = try? APIResponseDecoder.decode([MatchSelectablePlayer].self, from: data) {
            return players.filter { !$0.id.isEmpty }
        }

        struct SelectablePlayersPayload: Decodable {
            let players: [MatchSelectablePlayer]?
            let items: [MatchSelectablePlayer]?
            let all: [MatchSelectablePlayer]?
            let members: [MatchSelectablePlayer]?
            let guests: [MatchSelectablePlayer]?

            var resolved: [MatchSelectablePlayer] {
                if let all, !all.isEmpty {
                    return all
                }
                let combined = (members ?? []) + (guests ?? [])
                if !combined.isEmpty {
                    return combined
                }
                return players ?? items ?? []
            }
        }

        if let payload = try? APIResponseDecoder.decodePayload(SelectablePlayersPayload.self, from: data) {
            return payload.resolved.filter { !$0.id.isEmpty }
        }

        if let payload = try? JSONDecoder().decode(SelectablePlayersPayload.self, from: data) {
            return payload.resolved.filter { !$0.id.isEmpty }
        }

        return []
    }

    static func decodeEvents(from data: Data) throws -> [MatchEvent] {
        let events: [MatchEvent]
        if let decoded = try? APIResponseDecoder.decodePayload([MatchEvent].self, from: data) {
            events = decoded
        } else if let decoded = try? APIResponseDecoder.decode([MatchEvent].self, from: data) {
            events = decoded
        } else {
            struct EventsPayload: Decodable {
                let events: [MatchEvent]?
                let items: [MatchEvent]?
            }

            if let payload = try? APIResponseDecoder.decodePayload(EventsPayload.self, from: data) {
                events = payload.events ?? payload.items ?? []
            } else {
                events = []
            }
        }

        return events.filter(\.isActive)
    }
}

extension PublishBlocker {
    var localizedMessage: String {
        switch self {
        case .missingMinimalInfo:
            return L10n.publishBlockerMissingMinimalInfo
        case .missingComposition:
            return L10n.publishBlockerMissingComposition
        case .insufficientAvailabilityResponses:
            return L10n.publishBlockerInsufficientAvailability
        case .unknown(let code):
            return code
        }
    }
}

extension String {
    func snakeCaseToLowerCamel() -> String {
        let parts = split(separator: "_")
        guard let first = parts.first else { return self }
        let head = String(first)
        let tail = parts.dropFirst().map { part in
            part.prefix(1).uppercased() + part.dropFirst()
        }.joined()
        return head + tail
    }
}
