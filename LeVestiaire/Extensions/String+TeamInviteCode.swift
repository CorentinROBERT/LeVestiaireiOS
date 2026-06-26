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

    /// Heuristique : token unique alphanumérique court, sans espaces.
    var isLikelyTeamInviteCode: Bool {
        let trimmed = trimmingCharacters(in: .whitespacesAndNewlines)
        guard (4...24).contains(trimmed.count),
              !trimmed.contains(where: \.isWhitespace) else {
            return false
        }

        let allowed = CharacterSet.alphanumerics.union(CharacterSet(charactersIn: "-_"))
        return trimmed.unicodeScalars.allSatisfy { allowed.contains($0) }
    }

    /// Requête unifiée pour `GET /teams/search` : nom tel quel, code normalisé.
    var resolvedTeamSearchQuery: String {
        let trimmed = trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return "" }
        return trimmed.isLikelyTeamInviteCode
            ? trimmed.normalizedTeamInviteCode
            : trimmed
    }
}
