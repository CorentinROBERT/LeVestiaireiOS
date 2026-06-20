//
//  MatchEventDisplay.swift
//  LeVestaire
//

import Foundation

extension MatchEvent {
    var isDeletable: Bool {
        !type.isSystemGenerated
    }

    var displayLabel: String {
        var parts = [type.displayName]
        if let minute {
            parts.append("\(minute)'")
        }
        if let playerName, !playerName.isEmpty {
            parts.append(playerName)
        }
        return parts.joined(separator: " · ")
    }
}
