//
//  TeamSheetButtons.swift
//  LeVestaire
//

import SwiftUI

extension View {
    func secondarySheetButton() -> some View {
        self
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(AppPalette.Neutral.textSecondary)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .glassEffect(.regular, in: .rect(cornerRadius: 18))
            .buttonStyle(.plain)
    }

    func primarySheetButton(isLoading: Bool) -> some View {
        self
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(
                RoundedRectangle(cornerRadius: 18)
                    .fill(AppPalette.Primary.main)
            )
            .overlay {
                if isLoading {
                    ProgressView()
                        .tint(.white)
                }
            }
            .buttonStyle(.plain)
    }
}
