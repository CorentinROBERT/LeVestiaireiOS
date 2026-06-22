//
//  MatchLiveSection.swift
//  LeVestaire
//

import SwiftUI

struct MatchLiveSection: View {
    @ObservedObject var viewModel: MatchDetailViewModel
    @ObservedObject var eventsViewModel: MatchDetailEventsViewModel
    let match: MatchDetail

    @State private var showsAddEventSheet = false

    init(viewModel: MatchDetailViewModel, match: MatchDetail) {
        self.viewModel = viewModel
        self.eventsViewModel = viewModel.eventsViewModel
        self.match = match
    }

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

            if !eventsViewModel.sortedEvents.isEmpty {
                UCard(title: L10n.text("matchEvents"), icon: "clock.fill") {
                    MatchEventsTimelineView(
                        events: eventsViewModel.sortedEvents,
                        canManageEvents: match.capabilities.canManageEvents,
                        isSubmitting: eventsViewModel.isSubmitting,
                        onDelete: { eventId in
                            Task { await eventsViewModel.delete(eventId) }
                        }
                    )
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
            AddMatchEventSheet(
                viewModel: viewModel,
                eventsViewModel: viewModel.eventsViewModel
            )
        }
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

#if DEBUG
#Preview {
    MatchLiveSection(
        viewModel: .preview(status: .ongoing),
        match: MatchPreviewData.detail(status: .ongoing)
    )
    .padding()
    .teamPreviewEnvironment()
}
#endif
