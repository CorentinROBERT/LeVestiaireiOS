//
//  TeamInvitationStatusStyle.swift
//  LeVestaire
//

import SwiftUI

enum TeamInvitationStatusStyle {
    static func color(for status: TeamInvitationStatus) -> Color {
        switch status {
        case .pending:
            return AppPalette.Primary.main
        case .accepted:
            return AppPalette.Semantic.success
        case .declined, .cancelled:
            return AppPalette.Neutral.textSecondary
        case .expired:
            return AppPalette.Semantic.warning
        case .unknown:
            return AppPalette.Neutral.textTertiary
        }
    }
}
