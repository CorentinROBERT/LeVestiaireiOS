//
//  String+TeamInviteCode.swift
//  LeVestaire
//

import Foundation

extension String {
    /// Normalise un code d'invitation (trim + majuscules), aligné sur l'API.
    var normalizedTeamInviteCode: String {
        trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
    }
}
