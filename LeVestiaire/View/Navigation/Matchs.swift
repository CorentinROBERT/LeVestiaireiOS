//
//  Matchs.swift
//  LeVestaire
//
//  Created by Corentin Robert on 15/06/2026.
//

import SwiftUI

struct Matchs: View {
    @StateObject private var viewModel = MatchsViewModel()

    var body: some View {
        VStack(spacing: 16) {
            Text("Hello, World!")

            UButton(
                text: viewModel.isLoggingOut ? "Déconnexion..." : "Disconnect",
                onPress: viewModel.logout
            )
            .disabled(viewModel.isLoggingOut)
        }
    }
}

#Preview {
    Matchs()
}
