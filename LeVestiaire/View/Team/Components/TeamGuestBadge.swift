//
//  TeamGuestBadge.swift
//  LeVestaire
//

import SwiftUI

struct TeamGuestBadge: View {
    var body: some View {
        Text(L10n.text("guestLabel"))
            .font(.caption2.weight(.semibold))
            .foregroundStyle(AppPalette.Secondary.mintDark)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(AppPalette.Secondary.mint.opacity(0.14), in: Capsule())
            .accessibilityLabel(L10n.text("guestLabel"))
    }
}
