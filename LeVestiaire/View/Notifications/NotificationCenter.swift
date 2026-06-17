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

                Text("Aucune notification")
                    .font(.headline)
                    .foregroundStyle(AppPalette.Neutral.textPrimary)

                Text("Vos alertes matchs et équipe apparaîtront ici.")
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
