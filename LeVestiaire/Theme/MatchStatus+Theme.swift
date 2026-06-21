//
//  MatchStatus+Theme.swift
//  LeVestaire
//

import SwiftUI

extension MatchStatus {
    var color: Color {
        switch self {
        case .draft: return AppPalette.Neutral.textSecondary
        case .upcoming: return AppPalette.Primary.main
        case .ongoing: return AppPalette.Semantic.warning
        case .finished: return AppPalette.Semantic.success
        case .cancelled: return AppPalette.Semantic.error
        case .postponed: return AppPalette.Neutral.textTertiary
        }
    }
}
