//
//  MatchDetailView.swift
//  LeVestaire
//
//  Created by Corentin Robert on 17/06/2026.
//

import SwiftUI

struct MatchDetailView: View {
    let matchId: String
    var onLeave: ((String) -> Void)? = nil

    @StateObject private var viewModel: MatchDetailViewModel

    init(matchId: String, onLeave: ((String) -> Void)? = nil) {
        self.matchId = matchId
        self.onLeave = onLeave
        _viewModel = StateObject(wrappedValue: MatchDetailViewModel(matchId: matchId))
    }

    var body: some View {
        Group {
            if viewModel.isLoading, viewModel.match == nil {
                ProgressView(L10n.matchesLoading)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if let match = viewModel.match {
                matchContent(match)
            } else {
                placeholderContent
            }
        }
        .navigationTitle(viewModel.match?.title ?? L10n.matchDetailTitle)
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await viewModel.load()
        }
        .refreshable {
            await viewModel.refresh()
        }
        .onDisappear {
            onLeave?(matchId)
        }
    }

    private func matchContent(_ match: MatchDetail) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                matchHeroCard(match)

                if viewModel.showsRespondSection {
                    availabilityRespondSection(match)
                }

                if viewModel.showsPrepareHub {
                    MatchPrepareHubSection(viewModel: viewModel)
                }

                if match.status == .upcoming {
                    MatchUpcomingActionsSection(viewModel: viewModel)
                }

                if viewModel.showsLivePanel {
                    MatchLiveSection(viewModel: viewModel, match: match)
                }

                if !viewModel.showsPrepareHub, match.composition != nil {
                    MatchCompositionSummarySection(viewModel: viewModel, match: match)
                }

                if let errorMessage = viewModel.errorMessage {
                    Text(errorMessage)
                        .font(.caption)
                        .foregroundStyle(AppPalette.Semantic.error)
                }
            }
            .padding(20)
        }
    }

    private func matchHeroCard(_ match: MatchDetail) -> some View {
        UCard(title: match.resolvedStatusLabel, icon: "sportscourt.fill") {
            VStack(alignment: .leading, spacing: 8) {
                if let opponentTeam = match.opponentTeam, !opponentTeam.isEmpty {
                    Text(opponentTeam)
                        .font(.headline)
                        .foregroundStyle(AppPalette.Neutral.textPrimary)
                }

                if let location = match.location, !location.isEmpty {
                    Label(location, systemImage: "mappin.and.ellipse")
                        .font(.subheadline)
                        .foregroundStyle(AppPalette.Neutral.textSecondary)
                }

                if let scoreText = match.scoreText, match.status == .ongoing || match.status == .finished {
                    Text(scoreText)
                        .font(.title3.weight(.semibold))
                        .foregroundStyle(AppPalette.Primary.main)
                }

                if let summary = match.availabilitySummary,
                   match.status.isPreparationStatus {
                    Text(
                        L10n.availabilityResponsesSummary(
                            responded: summary.respondedCount,
                            total: summary.totalEligible
                        )
                    )
                    .font(.caption)
                    .foregroundStyle(AppPalette.Neutral.textSecondary)
                }
            }
        }
    }

    private func availabilityRespondSection(_ match: MatchDetail) -> some View {
        UCard(title: L10n.text("matchPhaseAvailability"), icon: "person.2.fill") {
            VStack(alignment: .leading, spacing: 12) {
                if let status = match.myAvailabilityStatus {
                    Text(L10n.myAvailabilityResponse(status.displayName))
                        .font(.caption)
                        .foregroundStyle(AppPalette.Neutral.textSecondary)
                }

                HStack(spacing: 8) {
                    ForEach(MatchAvailabilityStatus.allCases, id: \.self) { status in
                        availabilityChip(
                            status: status,
                            isSelected: match.myAvailabilityStatus == status
                        ) {
                            Task { await viewModel.submitMyAvailability(status) }
                        }
                    }
                }
            }
        }
    }

    private func availabilityChip(
        status: MatchAvailabilityStatus,
        isSelected: Bool,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            Text(status.displayName)
                .font(.caption.weight(.semibold))
                .foregroundStyle(isSelected ? AppPalette.Primary.onMain : AppPalette.Primary.main)
                .padding(.horizontal, 10)
                .padding(.vertical, 8)
                .frame(maxWidth: .infinity)
                .background(
                    Capsule()
                        .fill(isSelected ? AppPalette.Primary.main : AppPalette.Primary.soft)
                )
        }
        .buttonStyle(.plain)
        .disabled(viewModel.isSubmitting)
    }

    private var placeholderContent: some View {
        ScrollView {
            UCard(title: L10n.matchDetailTitle, icon: "sportscourt.fill") {
                Text(viewModel.errorMessage ?? L10n.matchDetailPlaceholder)
                    .font(.subheadline)
                    .foregroundStyle(AppPalette.Neutral.textSecondary)
            }
            .padding(20)
        }
    }
}

#Preview {
    NavigationStack {
        MatchDetailView(matchId: "preview-match")
            .environmentObject(LocalizationManager.shared)
            .environment(\.locale, LocalizationManager.shared.locale)
    }
}
