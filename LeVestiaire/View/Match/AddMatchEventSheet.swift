//
//  AddMatchEventSheet.swift
//  LeVestaire
//

import SwiftUI

struct AddMatchEventSheet: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var viewModel: MatchDetailViewModel
    @ObservedObject var eventsViewModel: MatchDetailEventsViewModel

    @State private var eventType: MatchEventType = .goal
    @State private var minute = ""
    @State private var selectedPlayerId: String?
    @State private var comment = ""
    @State private var sheetHeight: CGFloat = 520

    var body: some View {
        VStack(spacing: 0) {
            sheetHeader

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 20) {
                    eventTypeSection
                    minuteSection

                    if eventType.requiresPlayer {
                        playerSection
                    }

                    UGlassTextField(
                        placeholder: L10n.text("description"),
                        icon: "text.bubble",
                        text: $comment,
                        autocapitalization: .sentences
                    )
                    .disabled(eventsViewModel.isSubmitting)

                    if let errorMessage = viewModel.errorMessage {
                        Text(errorMessage)
                            .font(.caption)
                            .foregroundStyle(AppPalette.Semantic.error)
                    }

                    Button(L10n.text("addEventButton"), action: submitEvent)
                        .primarySheetButton(isLoading: eventsViewModel.isSubmitting)
                        .opacity(canSubmit ? 1 : 0.5)
                        .disabled(!canSubmit || eventsViewModel.isSubmitting)
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
        .task {
            await eventsViewModel.loadContext()
        }
    }

    private var sheetHeader: some View {
        HStack {
            Text(L10n.text("addEvent"))
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
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 20)
        .padding(.top, 28)
        .padding(.bottom, 12)
    }

    private var eventTypeSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(L10n.text("eventTypeLabel"))
                .font(.caption.weight(.semibold))
                .foregroundStyle(AppPalette.Neutral.textSecondary)

            Picker(L10n.text("eventTypeLabel"), selection: $eventType) {
                ForEach(MatchEventType.userCreatableCases, id: \.self) { type in
                    Text(type.displayName).tag(type)
                }
            }
            .pickerStyle(.menu)
            .tint(AppPalette.Primary.main)
            .disabled(eventsViewModel.isSubmitting)
            .onChange(of: eventType) { _, newValue in
                if !newValue.requiresPlayer {
                    selectedPlayerId = nil
                }
            }
        }
    }

    private var minuteSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(L10n.text("minuteOptional"))
                .font(.caption.weight(.semibold))
                .foregroundStyle(AppPalette.Neutral.textSecondary)

            UGlassTextField(
                placeholder: "23",
                icon: "clock.fill",
                text: $minute,
                keyboardType: .numberPad
            )
            .disabled(eventsViewModel.isSubmitting)
        }
    }

    private var playerSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(L10n.selectPlayer)
                .font(.caption.weight(.semibold))
                .foregroundStyle(AppPalette.Neutral.textSecondary)

            if eventsViewModel.eventPlayerOptions.isEmpty {
                Text(L10n.text("noPlayersAvailable"))
                    .font(.caption)
                    .foregroundStyle(AppPalette.Neutral.textTertiary)
            } else {
                Picker(L10n.selectPlayer, selection: $selectedPlayerId) {
                    Text(L10n.select).tag(Optional<String>.none)
                    ForEach(eventsViewModel.eventPlayerOptions) { player in
                        Text(player.name).tag(Optional(player.id))
                    }
                }
                .pickerStyle(.menu)
                .tint(AppPalette.Primary.main)
                .disabled(eventsViewModel.isSubmitting)
            }
        }
    }

    private var canSubmit: Bool {
        if !isMinuteValid {
            return false
        }

        if eventType.requiresPlayer {
            return selectedPlayerId != nil
        }

        return true
    }

    private var isMinuteValid: Bool {
        let trimmed = minute.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty {
            return true
        }
        guard let parsedMinute = Int(trimmed) else {
            return false
        }
        return parsedMinute >= 0
    }

    private var parsedMinute: Int? {
        let trimmed = minute.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }
        return Int(trimmed)
    }

    private func submitEvent() {
        guard isMinuteValid else { return }

        let trimmedComment = comment.trimmingCharacters(in: .whitespacesAndNewlines)

        Task {
            let success = await eventsViewModel.create(
                CreateMatchEventRequest(
                    type: eventType,
                    minute: parsedMinute,
                    player: eventType.requiresPlayer ? selectedPlayerId : nil,
                    comment: trimmedComment.isEmpty ? nil : trimmedComment
                )
            )
            if success {
                dismiss()
            }
        }
    }
}

#if DEBUG
#Preview {
    let viewModel = MatchDetailViewModel(matchId: "preview")
    AddMatchEventSheet(
        viewModel: viewModel,
        eventsViewModel: viewModel.eventsViewModel
    )
    .teamPreviewEnvironment()
}
#endif

private struct MatchSheetHeightPreferenceKey: PreferenceKey {
    static var defaultValue: CGFloat = 0

    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = max(value, nextValue())
    }
}
