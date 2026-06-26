//
//  CreateMatchSheet.swift
//  LeVestaire
//
//  Created by Corentin Robert on 17/06/2026.
//

import SwiftUI

struct CreateMatchSheet: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel = CreateMatchViewModel()

    let onCreated: (MatchDetail) -> Void

    @State private var sheetHeight: CGFloat = 620

    init(onCreated: @escaping (MatchDetail) -> Void = { _ in }) {
        self.onCreated = onCreated
    }

    var body: some View {
        VStack(spacing: 0) {
            sheetHeader

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 20) {
                    if viewModel.isLoadingTeams {
                        ProgressView(L10n.loading)
                            .frame(maxWidth: .infinity)
                    } else if viewModel.manageableTeams.isEmpty {
                        emptyTeamsState
                    } else {
                        formContent
                    }
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
                        key: MatchSheetHeightPreferenceKey.self,
                        value: geometry.size.height
                    )
                }
            }
        }
        .onPreferenceChange(MatchSheetHeightPreferenceKey.self) { height in
            guard height > 0 else { return }
            sheetHeight = min(height, 720)
        }
        .presentationDetents([.height(sheetHeight)])
        .presentationDragIndicator(.visible)
        .task {
            await viewModel.loadTeams(force: true)
        }
    }

    private var sheetHeader: some View {
        HStack {
            Text(L10n.createMatchTitle)
                .font(.headline)
                .foregroundStyle(AppPalette.Neutral.textPrimary)

            Spacer()

            Button(L10n.close) {
                dismiss()
            }
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(AppPalette.Primary.main)
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .glassEffect(.regular, in: .rect(cornerRadius: 20))
            .buttonStyle(.fullTap)
        }
        .padding(.horizontal, 20)
        .padding(.top, 28)
        .padding(.bottom, 12)
    }

    private var formContent: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text(L10n.matchCreatedDraftHint)
                .font(.caption)
                .foregroundStyle(AppPalette.Neutral.textSecondary)

            if viewModel.showsTeamPicker {
                teamPicker
            }

            UGlassTextField(
                placeholder: L10n.text("opponentTeam"),
                icon: "shield.fill",
                text: $viewModel.opponentTeam,
                autocapitalization: .words
            )

            UGlassTextField(
                placeholder: L10n.text("matchLocation"),
                icon: "mappin.and.ellipse",
                text: $viewModel.location,
                autocapitalization: .words
            )

            dateSection

            UGlassTextField(
                placeholder: L10n.text("description"),
                icon: "text.alignleft",
                text: $viewModel.description,
                autocapitalization: .sentences
            )

            if let errorMessage = viewModel.errorMessage {
                Text(errorMessage)
                    .font(.caption)
                    .foregroundStyle(AppPalette.Semantic.error)
            }

            UButton(
                text: L10n.createMatch,
                textColor: AppPalette.Primary.onMain,
                backgroundColor: AppPalette.Primary.main,
                cornerRadius: 12,
                isFullWidth: true,
                onPress: {
                    Task {
                        if let match = await viewModel.createMatch() {
                            onCreated(match)
                            dismiss()
                        }
                    }
                }
            )
            .opacity(viewModel.canSubmit ? 1 : 0.5)
            .disabled(!viewModel.canSubmit)
        }
    }

    private var teamPicker: some View {
        UMenuPicker(title: L10n.team, selection: $viewModel.selectedTeamId) {
            ForEach(viewModel.manageableTeams) { team in
                Text(team.name).tag(Optional(team.id))
            }
        }
    }

    private var dateSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            UDatePickerRow(
                title: L10n.text("matchDate"),
                selection: $viewModel.matchDate,
                minimumDate: Date(),
                displayedComponents: .date
            )

            UDatePickerRow(
                title: L10n.text("matchTime"),
                selection: $viewModel.matchTime,
                displayedComponents: .hourAndMinute
            )
        }
        .padding(14)
        .glassEffect(.regular, in: .rect(cornerRadius: 14))
    }

    private var emptyTeamsState: some View {
        UCard(icon: "person.3.fill", iconTint: AppPalette.Neutral.textTertiary) {
            Text(
                viewModel.hasInactiveManageableTeams
                    ? L10n.text("inactiveTeamMessage")
                    : L10n.createMatchNoManageableTeam
            )
            .font(.subheadline)
            .foregroundStyle(AppPalette.Neutral.textSecondary)
            .multilineTextAlignment(.center)
            .frame(maxWidth: .infinity)
        }
    }
}

private struct MatchSheetHeightPreferenceKey: PreferenceKey {
    static var defaultValue: CGFloat = 0

    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = max(value, nextValue())
    }
}

#if DEBUG
#Preview {
    CreateMatchSheet()
        .environmentObject(LocalizationManager.shared)
        .environment(\.locale, LocalizationManager.shared.locale)
}
#endif
