//
//  CreateTeamSheet.swift
//  LeVestaire
//

import SwiftUI
import UIKit

struct CreateTeamSheet: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var viewModel: TeamViewModel

    @State private var teamName = ""
    @State private var teamDescription = ""
    @State private var logoImage: UIImage?
    @State private var sheetHeight: CGFloat = 520

    var body: some View {
        VStack(spacing: 0) {
            sheetHeader

            ScrollView(showsIndicators: false) {
                VStack(spacing: 20) {
                    ProfilePhotoPicker(
                        selectedImage: $logoImage,
                        remoteImageURL: nil,
                        initials: teamName.isEmpty ? "?" : String(teamName.prefix(1)).uppercased(),
                        isUploading: false
                    )

                    Text(L10n.text("teamLogoOptional"))
                        .font(.caption)
                        .foregroundStyle(AppPalette.Neutral.textSecondary)

                    UGlassTextField(
                        placeholder: L10n.text("teamNameHint"),
                        icon: "person.3.fill",
                        text: $teamName,
                        autocapitalization: .words
                    )

                    UGlassTextField(
                        placeholder: L10n.text("teamDescriptionHint"),
                        icon: "text.alignleft",
                        text: $teamDescription,
                        autocapitalization: .sentences
                    )

                    actionRow
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 20)
            }
        }
        .padding(.top, 8)
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
            sheetHeight = min(height, 640)
        }
        .presentationDetents([.height(sheetHeight)])
        .presentationDragIndicator(.visible)
    }

    private var sheetHeader: some View {
        HStack {
            Text(L10n.text("creerNouvelleEquipe"))
                .font(.headline)
                .foregroundStyle(AppPalette.Neutral.textPrimary)
            Spacer()
        }
        .padding(.horizontal, 20)
        .padding(.top, 28)
        .padding(.bottom, 12)
    }

    private var actionRow: some View {
        HStack(spacing: 12) {
            Button(L10n.cancel) {
                dismiss()
            }
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(AppPalette.Neutral.textSecondary)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .glassEffect(.regular, in: .rect(cornerRadius: 18))
            .buttonStyle(.fullTap)

            Button {
                Task {
                    let success = await viewModel.createTeam(
                        name: teamName,
                        description: teamDescription,
                        logo: logoImage
                    )
                    if success {
                        dismiss()
                    }
                }
            } label: {
                Group {
                    if viewModel.isSubmitting {
                        ProgressView()
                            .tint(.white)
                    } else {
                        Text(L10n.text("creerUneEquipe"))
                    }
                }
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(
                    RoundedRectangle(cornerRadius: 18)
                        .fill(AppPalette.Primary.main)
                )
            }
            .buttonStyle(.fullTap)
            .disabled(viewModel.isSubmitting)
        }
    }
}

struct TeamSheetHeightPreferenceKey: PreferenceKey {
    static var defaultValue: CGFloat = 0

    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = max(value, nextValue())
    }
}

#if DEBUG
#Preview {
    CreateTeamSheet(viewModel: .preview())
        .teamPreviewEnvironment()
}
#endif
