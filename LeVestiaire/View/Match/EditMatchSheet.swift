//
//  EditMatchSheet.swift
//  LeVestaire
//

import SwiftUI

struct EditMatchSheet: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel: EditMatchViewModel

    let onSaved: (MatchDetail) -> Void

    @State private var sheetHeight: CGFloat = 580

    init(match: MatchDetail, onSaved: @escaping (MatchDetail) -> Void) {
        _viewModel = StateObject(wrappedValue: EditMatchViewModel(match: match))
        self.onSaved = onSaved
    }

    var body: some View {
        VStack(spacing: 0) {
            sheetHeader

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 20) {
                    formContent
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
            sheetHeight = min(height, 680)
        }
        .presentationDetents([.height(sheetHeight)])
        .presentationDragIndicator(.visible)
    }

    private var sheetHeader: some View {
        HStack {
            Text(L10n.editMatchTitle)
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

            if let errorMessage = viewModel.errorMessage {
                Text(errorMessage)
                    .font(.caption)
                    .foregroundStyle(AppPalette.Semantic.error)
            }

            UButton(
                text: L10n.saveChanges,
                textColor: AppPalette.Primary.onMain,
                backgroundColor: AppPalette.Primary.main,
                cornerRadius: 12,
                isFullWidth: true,
                onPress: {
                    Task {
                        if let match = await viewModel.saveChanges() {
                            onSaved(match)
                            dismiss()
                        }
                    }
                }
            )
            .opacity(viewModel.canSubmit ? 1 : 0.5)
            .disabled(!viewModel.canSubmit)
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

            Toggle(L10n.includeMatchTime, isOn: $viewModel.includesTime)
                .font(.subheadline)
                .tint(AppPalette.Primary.main)

            if viewModel.includesTime {
                UDatePickerRow(
                    title: L10n.text("matchTime"),
                    selection: $viewModel.matchTime,
                    displayedComponents: .hourAndMinute
                )
            }
        }
        .padding(14)
        .glassEffect(.regular, in: .rect(cornerRadius: 14))
    }
}

private struct MatchSheetHeightPreferenceKey: PreferenceKey {
    static var defaultValue: CGFloat = 0

    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = max(value, nextValue())
    }
}
