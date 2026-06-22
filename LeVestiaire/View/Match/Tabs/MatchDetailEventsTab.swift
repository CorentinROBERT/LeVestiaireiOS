//
//  MatchDetailEventsTab.swift
//  LeVestaire
//

import SwiftUI

struct MatchDetailEventsTab: View {
    @ObservedObject var viewModel: MatchDetailViewModel
    @ObservedObject var eventsViewModel: MatchDetailEventsViewModel
    let match: MatchDetail

    @State private var showsAddEventSheet = false

    init(viewModel: MatchDetailViewModel, match: MatchDetail) {
        self.viewModel = viewModel
        self.eventsViewModel = viewModel.eventsViewModel
        self.match = match
    }

    private var canManageEvents: Bool {
        eventsViewModel.canManage
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
            } else if eventsViewModel.isLoadingEvents, eventsViewModel.sortedEvents.isEmpty {
                ProgressView(L10n.loading)
                    .frame(maxWidth: .infinity, minHeight: 120)
            } else if eventsViewModel.sortedEvents.isEmpty {
                TeamEmptyState(
                    icon: "clock.fill",
                    title: L10n.text("matchEvents"),
                    message: L10n.text("eventsWillAppearHere")
                )
            } else {
                MatchEventsTimelineView(
                    events: eventsViewModel.sortedEvents,
                    canManageEvents: canManageEvents,
                    isSubmitting: eventsViewModel.isSubmitting,
                    onDelete: { eventId in
                        Task { await eventsViewModel.delete(eventId) }
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
            await eventsViewModel.loadIfNeeded()
            if eventsViewModel.canManage {
                await eventsViewModel.loadContext()
            }
        }
        .onChange(of: eventsViewModel.canManage) { _, canManage in
            guard canManage else { return }
            Task { await eventsViewModel.loadContext() }
        }
        .sheet(isPresented: $showsAddEventSheet) {
            AddMatchEventSheet(
                viewModel: viewModel,
                eventsViewModel: eventsViewModel
            )
        }
    }
}

#if DEBUG
#Preview {
    MatchDetailEventsTab(
        viewModel: .preview(status: .finished),
        match: MatchPreviewData.detail(status: .finished)
    )
    .padding()
    .teamPreviewEnvironment()
}
#endif
