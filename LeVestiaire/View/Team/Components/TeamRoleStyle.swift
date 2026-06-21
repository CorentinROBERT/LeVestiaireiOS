//
//  TeamRoleStyle.swift
//  LeVestaire
//

import SwiftUI

enum TeamRoleStyle {
    static func color(for role: TeamRole?) -> Color {
        switch role {
        case .admin:
            return AppPalette.Primary.main
        case .manager:
            return AppPalette.Secondary.coral
        case .player, .none:
            return AppPalette.Neutral.textSecondary
        }
    }

    static func backgroundColor(for role: TeamRole?) -> Color {
        color(for: role).opacity(0.14)
    }
}
