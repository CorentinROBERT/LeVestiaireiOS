//
//  CreateMatchSheet.swift
//  LeVestaire
//
//  Created by Corentin Robert on 17/06/2026.
//

import SwiftUI

struct CreateMatchSheet: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                UCard(title: "Nouveau match", icon: "plus.circle.fill") {
                    Text("Le formulaire de création de match sera disponible prochainement.")
                        .font(.subheadline)
                        .foregroundStyle(AppPalette.Neutral.textSecondary)
                }
                .padding(20)
            }
            .navigationTitle("Créer un match")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Fermer") {
                        dismiss()
                    }
                }
            }
        }
        .presentationDetents([.medium, .large])
    }
}

#Preview {
    CreateMatchSheet()
}
