//
//  TeamPlayerStatBadge.swift
//  LeVestaire
//

import SwiftUI

struct TeamPlayerStatBadge: View {
    let label: String
    let value: Int

    var body: some View {
        VStack(spacing: 2) {
            Text("\(value)")
                .font(.caption.weight(.bold))
                .foregroundStyle(AppPalette.Primary.dark)
            Text(label)
                .font(.caption2)
                .foregroundStyle(AppPalette.Neutral.textSecondary)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(label), \(value)")
    }
}
