//
//  TeamJerseyBadge.swift
//  LeVestaire
//

import SwiftUI

struct TeamJerseyBadge: View {
    let number: Int

    var body: some View {
        Text("\(number)")
            .font(.caption.weight(.bold))
            .foregroundStyle(AppPalette.Primary.dark)
            .frame(width: 28, height: 28)
            .background(AppPalette.Primary.soft, in: Circle())
            .accessibilityLabel(L10n.format("jerseyNumberWithValue", number))
    }
}
