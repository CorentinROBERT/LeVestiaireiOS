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
                Text(L10n.profileSettingsDescription)
                    .font(.subheadline)
                    .foregroundStyle(AppPalette.Neutral.textSecondary)
                    .frame(maxWidth: .infinity, alignment: .leading)

                UButton(
                    text: viewModel.isLoggingOut ? L10n.logoutInProgress : L10n.signOutButton,
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
