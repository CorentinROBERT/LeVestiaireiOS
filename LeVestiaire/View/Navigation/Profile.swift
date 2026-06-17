//
//  Profile.swift
//  LeVestaire
//
//  Created by Corentin Robert on 15/06/2026.
//

import SwiftUI

struct Profile: View {
    @StateObject private var viewModel = ProfileViewModel()

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 20) {
                Text("Paramètres et informations de votre compte.")
                    .font(.subheadline)
                    .foregroundStyle(AppPalette.Neutral.textSecondary)
                    .frame(maxWidth: .infinity, alignment: .leading)

                UButton(
                    text: viewModel.isLoggingOut ? "Déconnexion..." : "Se déconnecter",
                    textColor: AppPalette.Primary.onMain,
                    backgroundColor: AppPalette.Primary.main,
                    cornerRadius: 20,
                    isFullWidth: true,
                    trailingIcon: "rectangle.portrait.and.arrow.right",
                    onPress: viewModel.logout
                )
                .disabled(viewModel.isLoggingOut)
            }
            .padding(.horizontal, 20)
            .padding(.top, 8)
            .padding(.bottom, 24)
        }
    }
}

#Preview {
    Profile()
        .background(AuthScreenBackground())
}
