//
//  NotificationCenter.swift
//  LeVestaire
//
//  Created by Corentin Robert on 15/06/2026.
//

import SwiftUI

struct NotificationsView: View {
    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                Image(systemName: "bell.slash")
                    .font(.system(size: 40))
                    .foregroundStyle(AppPalette.Primary.muted)

                Text(L10n.noNotifications)
                    .font(.headline)
                    .foregroundStyle(AppPalette.Neutral.textPrimary)

                Text(L10n.noNotificationsDescription)
                    .font(.subheadline)
                    .foregroundStyle(AppPalette.Neutral.textSecondary)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .padding(32)
        }
    }
}

#Preview {
    NavigationStack {
        NotificationsView()
            .navigationTitle("Notifications")
    }
}
