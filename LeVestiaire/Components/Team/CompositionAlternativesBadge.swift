//
//  CompositionAlternativesBadge.swift
//  LeVestaire
//

import SwiftUI

struct CompositionAlternativesBadge: View {
    let count: Int

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: "square.stack.3d.up.fill")
                .font(.caption2)
            Text(L10n.compositionAlternativesLabel(count: count))
                .font(.caption2.weight(.medium))
        }
        .foregroundStyle(AppPalette.Primary.main)
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background {
            Capsule()
                .fill(AppPalette.Primary.soft)
        }
        .accessibilityLabel(L10n.compositionAlternativesLabel(count: count))
    }
}

#if DEBUG
#Preview {
    CompositionAlternativesBadge(count: 2)
        .padding()
        .teamPreviewEnvironment()
}
#endif
