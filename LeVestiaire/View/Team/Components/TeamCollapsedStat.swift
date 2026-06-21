//
//  TeamCollapsedStat.swift
//  LeVestaire
//

import SwiftUI

struct TeamCollapsedStat: View {
    let label: String
    let value: Int

    var body: some View {
        VStack(spacing: 4) {
            Text("\(value)")
                .font(.headline)
                .foregroundStyle(AppPalette.Primary.dark)
            Text(label)
                .font(.caption2)
                .foregroundStyle(AppPalette.Neutral.textSecondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(label), \(value)")
    }
}
