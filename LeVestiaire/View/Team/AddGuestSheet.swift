//
//  AddGuestSheet.swift
//  LeVestaire
//

import SwiftUI

struct AddGuestSheet: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var rosterViewModel: TeamRosterViewModel

    @State private var firstName = ""
    @State private var lastName = ""
    @State private var email = ""
    @State private var jerseyNumber = ""
    @State private var sheetHeight: CGFloat = 520

    private var optionalEmailPlaceholder: String {
        "\(L10n.email) (\(L10n.text("optional")))"
    }

    private var optionalJerseyPlaceholder: String {
        "\(L10n.text("jerseyNumber")) (\(L10n.text("optional")))"
    }

    init(viewModel: TeamViewModel) {
        self.rosterViewModel = viewModel.rosterViewModel
    }

    var body: some View {
        VStack(spacing: 20) {
            Text(L10n.text("addGuestDescription"))
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
                placeholder: optionalEmailPlaceholder,
                icon: "envelope.fill",
                text: $email,
                keyboardType: .emailAddress,
                textContentType: .emailAddress
            )

            UGlassTextField(
                placeholder: optionalJerseyPlaceholder,
                icon: "tshirt.fill",
                text: $jerseyNumber,
                keyboardType: .numberPad
            )

            HStack(spacing: 12) {
                Button(L10n.cancel) { dismiss() }
                    .secondarySheetButton()

                Button(L10n.text("addGuest")) {
                    Task {
                        let parsedJersey = Int(jerseyNumber.trimmingCharacters(in: .whitespacesAndNewlines))
                        let success = await rosterViewModel.addGuest(
                            firstName: firstName,
                            lastName: lastName,
                            email: email,
                            jerseyNumber: parsedJersey
                        )
                        if success { dismiss() }
                    }
                }
                .primarySheetButton(isLoading: rosterViewModel.isSubmitting)
                .disabled(rosterViewModel.isSubmitting)
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
    AddGuestSheet(viewModel: .preview())
        .teamPreviewEnvironment()
}
#endif
