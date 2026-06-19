//
//  MatchLiveSection.swift
//  LeVestaire
//

import SwiftUI

struct MatchLiveSection: View {
    @ObservedObject var viewModel: MatchDetailViewModel
    let match: MatchDetail

    @State private var showsAddEventSheet = false

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            if let scoreText = match.scoreText {
                UCard(title: L10n.text("score"), icon: "sportscourt.fill") {
                    Text(scoreText)
                        .font(.title2.weight(.bold))
                        .foregroundStyle(AppPalette.Primary.main)
                        .frame(maxWidth: .infinity, alignment: .center)
                }
            }

            if match.capabilities.canManageEvents {
                UButton(
                    text: L10n.text("addEvent"),
                    textColor: AppPalette.Primary.onMain,
                    backgroundColor: AppPalette.Primary.main,
                    cornerRadius: 12,
                    isFullWidth: true,
                    onPress: {
                        showsAddEventSheet = true
                    }
                )
            }

            if !viewModel.sortedEvents.isEmpty {
                UCard(title: L10n.text("matchEvents"), icon: "clock.fill") {
                    VStack(alignment: .leading, spacing: 8) {
                        ForEach(viewModel.sortedEvents) { event in
                            HStack(alignment: .top, spacing: 8) {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(eventLabel(event))
                                        .font(.caption.weight(.semibold))
                                        .foregroundStyle(AppPalette.Neutral.textPrimary)

                                    if let comment = event.comment, !comment.isEmpty {
                                        Text(comment)
                                            .font(.caption2)
                                            .foregroundStyle(AppPalette.Neutral.textSecondary)
                                    }
                                }

                                Spacer(minLength: 8)

                                if match.capabilities.canManageEvents {
                                    Button(role: .destructive) {
                                        Task { await viewModel.deleteEvent(event.id) }
                                    } label: {
                                        Image(systemName: "trash")
                                            .font(.caption)
                                    }
                                    .buttonStyle(.plain)
                                    .disabled(viewModel.isSubmitting)
                                }
                            }
                        }
                    }
                }
            }

            if match.capabilities.canFinishMatch {
                UButton(
                    text: L10n.text("finishMatch"),
                    textColor: AppPalette.Primary.onMain,
                    backgroundColor: AppPalette.Semantic.success,
                    cornerRadius: 12,
                    isFullWidth: true,
                    onPress: {
                        Task { await viewModel.finishMatch() }
                    }
                )
            }
        }
        .sheet(isPresented: $showsAddEventSheet) {
            AddMatchEventSheet(viewModel: viewModel)
        }
    }

    private func eventLabel(_ event: MatchEvent) -> String {
        if let minute = event.minute {
            return "\(event.type.displayName) · \(minute)'"
        }
        return event.type.displayName
    }
}

struct MatchUpcomingActionsSection: View {
    @ObservedObject var viewModel: MatchDetailViewModel

    var body: some View {
        if viewModel.match?.capabilities.canStartMatch == true {
            UButton(
                text: L10n.text("startMatch"),
                textColor: AppPalette.Primary.onMain,
                backgroundColor: AppPalette.Primary.main,
                cornerRadius: 12,
                isFullWidth: true,
                onPress: {
                    Task { await viewModel.startMatch() }
                }
            )
        }
    }
}
