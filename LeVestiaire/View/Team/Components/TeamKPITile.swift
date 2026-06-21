//
//  TeamKPITile.swift
//  LeVestaire
//

import SwiftUI

struct TeamKPITile: View {
    private static let tileHeight: CGFloat = 84
    private static let valueHeight: CGFloat = 30
    private static let labelHeight: CGFloat = 30
    private static let unavailableValue = "—"

    let value: String
    let label: String
    var accent: Color = AppPalette.Primary.main
    var isUnavailable: Bool = false

    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.title2.weight(.bold))
                .foregroundStyle(isUnavailable ? AppPalette.Neutral.textTertiary : accent)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
                .frame(height: Self.valueHeight)

            Text(label)
                .font(.caption2)
                .foregroundStyle(AppPalette.Neutral.textSecondary)
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .minimumScaleFactor(0.75)
                .frame(maxWidth: .infinity)
                .frame(height: Self.labelHeight, alignment: .center)
                .padding(.horizontal, 4)
        }
        .frame(maxWidth: .infinity)
        .frame(height: Self.tileHeight)
        .glassEffect(.regular, in: .rect(cornerRadius: 16))
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(label), \(value)")
    }

    static var unavailablePlaceholder: String { unavailableValue }
}
