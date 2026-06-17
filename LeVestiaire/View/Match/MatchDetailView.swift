//
//  MatchDetailView.swift
//  LeVestaire
//
//  Created by Corentin Robert on 17/06/2026.
//

import SwiftUI

struct MatchDetailView: View {
    let matchId: String

    var body: some View {
        ScrollView {
            UCard(title: L10n.matchDetailTitle, icon: "sportscourt.fill") {
                Text(L10n.matchDetailPlaceholder)
                    .font(.subheadline)
                    .foregroundStyle(AppPalette.Neutral.textSecondary)
            }
            .padding(20)
        }
        .navigationTitle(L10n.matchDetailTitle)
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    NavigationStack {
        MatchDetailView(matchId: "preview-match")
            .environmentObject(LocalizationManager.shared)
            .environment(\.locale, LocalizationManager.shared.locale)
    }
}
