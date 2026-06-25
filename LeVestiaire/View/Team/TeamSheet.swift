//
//  TeamSheet.swift
//  LeVestaire
//

import Foundation

enum TeamSheet: Identifiable, Equatable {
    case createTeam
    case joinTeam
    case settings
    case invitePlayer
    case shareTeamInvite
    case addGuest
    case compositionEditor(TeamComposition?)

    var id: String {
        switch self {
        case .createTeam:
            return "createTeam"
        case .joinTeam:
            return "joinTeam"
        case .settings:
            return "settings"
        case .invitePlayer:
            return "invitePlayer"
        case .shareTeamInvite:
            return "shareTeamInvite"
        case .addGuest:
            return "addGuest"
        case .compositionEditor(let composition):
            return "composition-\(composition?.id ?? "new")"
        }
    }

    var composition: TeamComposition? {
        guard case .compositionEditor(let composition) = self else { return nil }
        return composition
    }
}
