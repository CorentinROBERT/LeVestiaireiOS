//
//  MatchDetailEventsTab.swift
//  LeVestaire
//

import SwiftUI

struct MatchDetailEventsTab: View {
    @ObservedObject var viewModel: MatchDetailViewModel
    let match: MatchDetail

    @State private var showsAddEventSheet = false

    private var canManageEvents: Bool {
        viewModel.canManageMatchEvents
    }

    private var canFinishMatch: Bool {
        match.capabilities.canFinishMatch
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            if match.status == .upcoming {
                TeamEmptyState(
                    icon: "clock.fill",
                    title: L10n.text("matchNotStartedYet"),
                    message: L10n.text("eventsWillAppearHere")
                )
            } else if viewModel.isLoadingEvents, viewModel.sortedEvents.isEmpty {
                ProgressView(L10n.loading)
                    .frame(maxWidth: .infinity, minHeight: 120)
            } else if viewModel.sortedEvents.isEmpty {
                TeamEmptyState(
                    icon: "clock.fill",
                    title: L10n.text("matchEvents"),
                    message: L10n.text("eventsWillAppearHere")
                )
            } else {
                MatchEventsTimelineView(
                    events: viewModel.sortedEvents,
                    canManageEvents: canManageEvents,
                    isSubmitting: viewModel.isSubmitting,
                    onDelete: { eventId in
                        Task { await viewModel.deleteEvent(eventId) }
                    }
                )
            }

            if canManageEvents {
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

            if canFinishMatch, match.status == .ongoing {
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
        .frame(maxWidth: .infinity, alignment: .leading)
        .task {
            await viewModel.loadEventsIfNeeded()
            if canManageEvents {
                await viewModel.loadEventContext()
            }
        }
        .sheet(isPresented: $showsAddEventSheet) {
            AddMatchEventSheet(viewModel: viewModel)
        }
    }
}
