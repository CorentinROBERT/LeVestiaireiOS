//
//  AccountDeletionNavigationBanner.swift
//  LeVestaire
//
//  Created by Corentin Robert on 18/06/2026.
//

import SwiftUI

struct AccountDeletionNavigationBanner: View {
    let daysRemaining: Int
    let onDismiss: () -> Void

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.body)
                .foregroundStyle(AppPalette.Semantic.warning)

            VStack(alignment: .leading, spacing: 4) {
                Text(L10n.accountDeletionInProgress)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(AppPalette.Neutral.textPrimary)

                Text(L10n.accountDeletionScheduled(daysRemaining))
                    .font(.caption)
                    .foregroundStyle(AppPalette.Neutral.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 0)

            Button(action: onDismiss) {
                Image(systemName: "xmark")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(AppPalette.Neutral.textSecondary)
                    .frame(width: 28, height: 28)
                    .background(
                        Circle()
                            .fill(AppPalette.Neutral.surface.opacity(0.8))
                    )
            }
            .buttonStyle(.fullTap)
            .accessibilityLabel(L10n.close)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AppPalette.Semantic.warning.opacity(0.14))
        .overlay(alignment: .bottom) {
            Divider()
        }
    }
}

#Preview {
    AccountDeletionNavigationBanner(daysRemaining: 30, onDismiss: {})
}
