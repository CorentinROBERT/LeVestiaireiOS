//
//  TeamSectionErrorView.swift
//  LeVestaire
//

import SwiftUI

struct TeamSectionErrorView: View {
    let message: String
    let onRetry: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            TeamSectionErrorText(message: message)
            Button(L10n.retry, action: onRetry)
                .font(.caption.weight(.semibold))
                .foregroundStyle(AppPalette.Primary.main)
                .accessibilityHint(L10n.retry)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
