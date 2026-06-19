//
//  TeamToastBanner.swift
//  LeVestaire
//

import SwiftUI

struct TeamToastBanner: View {
    let message: String

    var body: some View {
        Text(message)
            .font(.subheadline.weight(.medium))
            .foregroundStyle(AppPalette.Neutral.textPrimary)
            .multilineTextAlignment(.center)
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .frame(maxWidth: .infinity)
            .background(AppPalette.Secondary.mint.opacity(0.16), in: RoundedRectangle(cornerRadius: 14))
            .overlay {
                RoundedRectangle(cornerRadius: 14)
                    .stroke(AppPalette.Secondary.mint.opacity(0.35), lineWidth: 1)
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 8)
    }
}
