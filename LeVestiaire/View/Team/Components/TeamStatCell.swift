//
//  TeamStatCell.swift
//  LeVestaire
//

import SwiftUI

struct TeamStatCell: View {
    let title: String
    let value: Int

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundStyle(AppPalette.Neutral.textSecondary)
            Text("\(value)")
                .font(.title3.weight(.semibold))
                .foregroundStyle(AppPalette.Primary.dark)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .glassEffect(.regular, in: .rect(cornerRadius: 14))
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(title), \(value)")
    }
}
