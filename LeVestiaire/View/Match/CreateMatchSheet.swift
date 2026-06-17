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
                UCard(title: L10n.createMatchTitle, icon: "plus.circle.fill") {
                    Text(L10n.createMatchPlaceholder)
                        .font(.subheadline)
                        .foregroundStyle(AppPalette.Neutral.textSecondary)
                }
                .padding(20)
            }
            .navigationTitle(L10n.createMatch)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(L10n.close) {
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
        .environmentObject(LocalizationManager.shared)
        .environment(\.locale, LocalizationManager.shared.locale)
}
