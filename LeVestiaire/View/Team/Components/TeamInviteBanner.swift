//
//  TeamInviteBanner.swift
//  LeVestaire
//

import SwiftUI

struct TeamInviteBanner: View {
    let teamName: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "person.3.fill")
                .font(.title3)
                .foregroundStyle(AppPalette.Primary.main)

            Text(L10n.format("teamInviteJoinBanner", teamName))
                .font(.subheadline)
                .foregroundStyle(AppPalette.Neutral.textPrimary)
                .multilineTextAlignment(.leading)

            Spacer(minLength: 0)
        }
        .padding(16)
        .glassEffect(.regular, in: .rect(cornerRadius: 16))
    }
}

#if DEBUG
#Preview {
    TeamInviteBanner(teamName: "FC Test")
        .padding()
        .background(AuthScreenBackground())
}
#endif
