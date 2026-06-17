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
            UCard(title: "Détail du match", icon: "sportscourt.fill") {
                Text("Le détail du match \(matchId) sera disponible prochainement.")
                    .font(.subheadline)
                    .foregroundStyle(AppPalette.Neutral.textSecondary)
            }
            .padding(20)
        }
        .navigationTitle("Match")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    NavigationStack {
        MatchDetailView(matchId: "preview-match")
    }
}
