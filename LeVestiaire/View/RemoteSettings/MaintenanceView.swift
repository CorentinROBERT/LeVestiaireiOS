//
//  MaintenanceView.swift
//  LeVestaire
//

import SwiftUI

struct MaintenanceView: View {
    let message: String

    var body: some View {
        ZStack {
            AuthScreenBackground()
                .ignoresSafeArea()

            VStack(spacing: 24) {
                Image(systemName: "wrench.and.screwdriver.fill")
                    .font(.system(size: 48))
                    .foregroundStyle(AppPalette.Secondary.coral)

                Text(L10n.maintenanceTitle)
                    .font(.title2.weight(.bold))
                    .foregroundStyle(AppPalette.Neutral.textPrimary)
                    .multilineTextAlignment(.center)

                Text(message)
                    .font(.body)
                    .foregroundStyle(AppPalette.Neutral.textSecondary)
                    .multilineTextAlignment(.center)
            }
            .padding(32)
        }
    }
}

#if DEBUG
#Preview {
    MaintenanceView(message: L10n.maintenanceDefaultMessage)
}
#endif
