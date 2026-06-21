//
//  TeamSectionErrorText.swift
//  LeVestaire
//

import SwiftUI

struct TeamSectionErrorText: View {
    let message: String

    var body: some View {
        Text(message)
            .font(.caption)
            .foregroundStyle(AppPalette.Semantic.error)
            .frame(maxWidth: .infinity, alignment: .leading)
            .accessibilityLabel(message)
    }
}
