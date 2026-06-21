//
//  MatchDetailTabsSection.swift
//  LeVestaire
//

import SwiftUI

struct MatchDetailTabsSection: View {
    @ObservedObject var viewModel: MatchDetailViewModel
    let match: MatchDetail
    let configuration: MatchDetailTabConfiguration

    @State private var selectedTab: MatchDetailTab

    init(
        viewModel: MatchDetailViewModel,
        match: MatchDetail,
        configuration: MatchDetailTabConfiguration
    ) {
        self.viewModel = viewModel
        self.match = match
        self.configuration = configuration
        _selectedTab = State(initialValue: configuration.defaultTab)
    }

    var body: some View {
        UCard(title: L10n.text("summary"), icon: "square.grid.2x2.fill") {
            VStack(alignment: .leading, spacing: 16) {
                if configuration.visibleTabs.count > 1 {
                    MatchDetailTabPicker(
                        tabs: configuration.visibleTabs,
                        selection: $selectedTab
                    )
                }

                tabContent(for: activeTab)
            }
        }
        .onChange(of: match.status) { _, _ in
            syncSelection(with: configuration)
        }
        .onChange(of: match.id) { _, _ in
            selectedTab = configuration.defaultTab
        }
        .onChange(of: selectedTab) { _, tab in
            Task { await viewModel.loadTabContentIfNeeded(tab) }
        }
        .task {
            await viewModel.loadTabContentIfNeeded(selectedTab)
        }
    }

    private var activeTab: MatchDetailTab {
        configuration.visibleTabs.contains(selectedTab)
            ? selectedTab
            : configuration.defaultTab
    }

    @ViewBuilder
    private func tabContent(for tab: MatchDetailTab) -> some View {
        switch tab {
        case .composition:
            MatchDetailCompositionTab(viewModel: viewModel, match: match)
        case .events:
            MatchDetailEventsTab(viewModel: viewModel, match: match)
        case .statistics:
            MatchDetailStatisticsTab(viewModel: viewModel, match: match)
        case .quiz:
            MatchDetailQuizTab(viewModel: viewModel, match: match)
        }
    }

    private func syncSelection(with configuration: MatchDetailTabConfiguration) {
        if !configuration.visibleTabs.contains(selectedTab) {
            selectedTab = configuration.defaultTab
        }
    }
}

#if DEBUG
#Preview {
    let match = MatchPreviewData.detail(status: .finished)
    let configuration = MatchDetailTabConfiguration.forMatch(match, showsPrepareHub: false)!
    MatchDetailTabsSection(
        viewModel: .preview(status: .finished),
        match: match,
        configuration: configuration
    )
    .padding()
    .teamPreviewEnvironment()
}
#endif
