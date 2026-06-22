//
//  ForceUpdateView.swift
//  LeVestaire
//

import SwiftUI

struct ForceUpdateView: View {
    let message: String
    let storeURL: URL?

    var body: some View {
        ZStack {
            AuthScreenBackground()
                .ignoresSafeArea()

            VStack(spacing: 24) {
                Image(systemName: "arrow.down.app.fill")
                    .font(.system(size: 48))
                    .foregroundStyle(AppPalette.Primary.main)

                Text(L10n.forceUpdateTitle)
                    .font(.title2.weight(.bold))
                    .foregroundStyle(AppPalette.Neutral.textPrimary)
                    .multilineTextAlignment(.center)

                Text(message)
                    .font(.body)
                    .foregroundStyle(AppPalette.Neutral.textSecondary)
                    .multilineTextAlignment(.center)

                if let storeURL {
                    Link(destination: storeURL) {
                        Text(L10n.updateOnAppStore)
                            .font(.headline)
                            .foregroundStyle(AppPalette.Primary.onMain)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(AppPalette.Primary.main, in: RoundedRectangle(cornerRadius: 16))
                    }
                }
            }
            .padding(32)
        }
    }
}

#if DEBUG
#Preview {
    ForceUpdateView(
        message: L10n.forceUpdateDefaultMessage,
        storeURL: URL(string: "https://apps.apple.com")
    )
}
#endif
