//
//  InvitePlayerSheet.swift
//  LeVestaire
//

import SwiftUI

struct InvitePlayerSheet: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var viewModel: TeamViewModel
    @ObservedObject var invitationsViewModel: TeamInvitationsViewModel

    @State private var firstName = ""
    @State private var lastName = ""
    @State private var email = ""
    @State private var sheetHeight: CGFloat = 460

    init(viewModel: TeamViewModel) {
        self.viewModel = viewModel
        self.invitationsViewModel = viewModel.invitationsViewModel
    }

    var body: some View {
        VStack(spacing: 20) {
            Text(L10n.format("invitePlayerDescription", viewModel.selectedTeam?.name ?? ""))
                .font(.subheadline)
                .foregroundStyle(AppPalette.Neutral.textSecondary)
                .frame(maxWidth: .infinity, alignment: .leading)

            UGlassTextField(
                placeholder: L10n.firstName,
                icon: "person.fill",
                text: $firstName,
                autocapitalization: .words
            )

            UGlassTextField(
                placeholder: L10n.lastName,
                icon: "person.fill",
                text: $lastName,
                autocapitalization: .words
            )

            UGlassTextField(
                placeholder: L10n.text("playerEmailHint"),
                icon: "envelope.fill",
                text: $email,
                keyboardType: .emailAddress,
                textContentType: .emailAddress
            )

            HStack(spacing: 12) {
                Button(L10n.cancel) { dismiss() }
                    .secondarySheetButton()

                Button(L10n.text("invite")) {
                    Task {
                        let success = await invitationsViewModel.invitePlayer(
                            email: email,
                            firstName: firstName,
                            lastName: lastName
                        )
                        if success { dismiss() }
                    }
                }
                .primarySheetButton(isLoading: invitationsViewModel.isSubmitting)
                .disabled(invitationsViewModel.isSubmitting)
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 28)
        .padding(.bottom, 20)
        .background {
            ZStack {
                AuthScreenBackground()
                GeometryReader { geometry in
                    Color.clear.preference(
                        key: TeamSheetHeightPreferenceKey.self,
                        value: geometry.size.height
                    )
                }
            }
        }
        .onPreferenceChange(TeamSheetHeightPreferenceKey.self) { height in
            guard height > 0 else { return }
            sheetHeight = height
        }
        .presentationDetents([.height(sheetHeight)])
        .presentationDragIndicator(.visible)
    }
}

#if DEBUG
#Preview {
    InvitePlayerSheet(viewModel: .preview())
        .teamPreviewEnvironment()
}
#endif
