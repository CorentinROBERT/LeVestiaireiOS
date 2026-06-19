//
//  TeamLoadErrorBanner.swift
//  LeVestaire
//

import SwiftUI

struct TeamLoadErrorBanner: View {
    let message: String
    let onRetry: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .top, spacing: 10) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundStyle(AppPalette.Semantic.warning)

                Text(message)
                    .font(.subheadline)
                    .foregroundStyle(AppPalette.Neutral.textPrimary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Button(L10n.retry, action: onRetry)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(AppPalette.Primary.main)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(AppPalette.Semantic.warning.opacity(0.12), in: RoundedRectangle(cornerRadius: 14))
    }
}
