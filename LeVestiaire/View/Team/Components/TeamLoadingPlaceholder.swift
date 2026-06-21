//
//  TeamLoadingPlaceholder.swift
//  LeVestaire
//

import SwiftUI

struct TeamLoadingPlaceholder: View {
    var rowCount: Int = 3

    var body: some View {
        VStack(spacing: 12) {
            ForEach(0..<rowCount, id: \.self) { _ in
                RoundedRectangle(cornerRadius: 14)
                    .fill(AppPalette.Primary.soft.opacity(0.45))
                    .frame(height: 56)
            }
        }
        .redacted(reason: .placeholder)
        .accessibilityLabel(L10n.loading)
    }
}
