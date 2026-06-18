//
//  Matchs.swift
//  LeVestaire
//
//  Created by Corentin Robert on 15/06/2026.
//

import SwiftUI

struct Matchs: View {
    @StateObject private var viewModel = MatchsViewModel()

    private enum ActionButtonMetrics {
        static let cornerRadius: CGFloat = 18
        static let verticalPadding: CGFloat = 12
        static let horizontalPadding: CGFloat = 14
        static let iconSize: CGFloat = 42

        static var height: CGFloat {
            verticalPadding * 2 + iconSize
        }
    }

    var body: some View {
        Group {
            if viewModel.isLoading && viewModel.matches.isEmpty {
                ProgressView(L10n.matchesLoading)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if let errorMessage = viewModel.errorMessage, viewModel.matches.isEmpty {
                errorState(message: errorMessage)
            } else {
                matchesList
            }
        }
        .navigationDestination(for: String.self) { matchId in
            MatchDetailView(matchId: matchId)
        }
        .sheet(isPresented: $viewModel.showsFilters) {
            MatchFiltersSheet(
                filters: $viewModel.filters,
                onApply: {
                    Task { await viewModel.applyFilters(viewModel.filters) }
                },
                onReset: {
                    Task { await viewModel.resetFilters() }
                }
            )
        }
        .sheet(isPresented: $viewModel.showsCreateMatch) {
            CreateMatchSheet()
        }
        .task {
            await viewModel.initialize()
        }
    }

    private var matchesList: some View {
        ScrollView(showsIndicators: false) {
            LazyVStack(spacing: 16) {
                actionsHeader

                if viewModel.hasActiveFilters {
                    activeFiltersBanner
                }

                if viewModel.totalItems > 0 {
                    matchesCountLabel
                }

                if viewModel.matches.isEmpty {
                    emptyState
                } else {
                    ForEach(viewModel.matches) { match in
                        NavigationLink(value: match.id) {
                            MatchCardView(match: match)
                        }
                        .buttonStyle(.plain)
                        .task {
                            await viewModel.loadNextPageIfNeeded(currentMatch: match)
                        }
                    }

                    paginationFooter
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 4)
            .padding(.bottom, 24)
        }
        .refreshable {
            await viewModel.refresh()
        }
    }

    // MARK: - Actions

    private var actionsHeader: some View {
        HStack(alignment: .center, spacing: 12) {
            createMatchButton
            filterButton
        }
    }

    private var createMatchButton: some View {
        Button {
            viewModel.showsCreateMatch = true
        } label: {
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [
                                    AppPalette.Primary.main,
                                    AppPalette.Primary.light
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: ActionButtonMetrics.iconSize, height: ActionButtonMetrics.iconSize)

                    Image(systemName: "plus")
                        .font(.system(size: 17, weight: .bold))
                        .foregroundStyle(AppPalette.Primary.onMain)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(L10n.newMatch)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(AppPalette.Neutral.textPrimary)

                    Text(L10n.planMatchSubtitle)
                        .font(.caption)
                        .foregroundStyle(AppPalette.Neutral.textSecondary)
                }

                Spacer(minLength: 0)
            }
            .padding(.horizontal, ActionButtonMetrics.horizontalPadding)
            .padding(.vertical, ActionButtonMetrics.verticalPadding)
            .frame(maxWidth: .infinity, minHeight: ActionButtonMetrics.height, alignment: .leading)
            .contentShape(.rect(cornerRadius: ActionButtonMetrics.cornerRadius))
            .glassEffect(.regular, in: .rect(cornerRadius: ActionButtonMetrics.cornerRadius))
        }
        .buttonStyle(.plain)
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityLabel(L10n.createMatch)
    }

    private var filterButton: some View {
        Button {
            viewModel.showsFilters = true
        } label: {
            ZStack(alignment: .topTrailing) {
                Image(systemName: "line.3.horizontal.decrease.circle.fill")
                    .font(.system(size: 35))
                    .symbolRenderingMode(.hierarchical)
                    .foregroundStyle(AppPalette.Primary.main)
                    .frame(
                        width: ActionButtonMetrics.height,
                        height: ActionButtonMetrics.height
                    )
                    .glassEffect(
                        .regular,
                        in: .rect(cornerRadius: ActionButtonMetrics.cornerRadius)
                    )

                if viewModel.hasActiveFilters {
                    Text("\(viewModel.activeFilterCount)")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(AppPalette.Primary.onMain)
                        .frame(minWidth: 18, minHeight: 18)
                        .background(Circle().fill(AppPalette.Semantic.error))
                        .overlay(Circle().stroke(AppPalette.Neutral.surface, lineWidth: 2))
                        .offset(x: 4, y: -4)
                }
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel(L10n.filterMatches)
    }

    private var activeFiltersBanner: some View {
        Button {
            viewModel.showsFilters = true
        } label: {
            HStack(spacing: 8) {
                Image(systemName: "slider.horizontal.3")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(AppPalette.Primary.main)

                Text(activeFiltersDescription)
                    .font(.caption)
                    .foregroundStyle(AppPalette.Neutral.textSecondary)
                    .lineLimit(1)

                Spacer(minLength: 0)

                Text(L10n.modify)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(AppPalette.Primary.main)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .glassEffect(.regular, in: .rect(cornerRadius: 12))
        }
        .buttonStyle(.plain)
    }

    private var activeFiltersDescription: String {
        var parts: [String] = []
        if !viewModel.filters.statuses.isEmpty {
            let labels = viewModel.filters.statuses
                .sorted { $0.rawValue < $1.rawValue }
                .map(\.displayName)
            parts.append(labels.joined(separator: ", "))
        }
        if viewModel.filters.fromDate != nil || viewModel.filters.toDate != nil {
            parts.append(L10n.customPeriod)
        }
        return parts.joined(separator: " · ")
    }

    private var matchesCountLabel: some View {
        Text(viewModel.loadedCountText)
            .font(.caption.weight(.medium))
            .foregroundStyle(AppPalette.Neutral.textSecondary)
            .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var emptyState: some View {
        UCard(icon: "sportscourt", iconTint: AppPalette.Neutral.textTertiary) {
            VStack(spacing: 8) {
                Text(L10n.noMatchesFound)
                    .font(.headline)
                    .foregroundStyle(AppPalette.Neutral.textPrimary)

                Text(L10n.createFirstMatchToStart)
                    .font(.subheadline)
                    .foregroundStyle(AppPalette.Neutral.textSecondary)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
        }
        .padding(.top, 8)
    }

    private var paginationFooter: some View {
        VStack(spacing: 8) {
            if viewModel.isLoadingMore {
                ProgressView()
            } else if viewModel.showsEndOfListMessage {
                Text(L10n.allMatchesLoaded)
                    .font(.caption)
                    .foregroundStyle(AppPalette.Neutral.textTertiary)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
    }

    private func errorState(message: String) -> some View {
        ScrollView {
            VStack(spacing: 16) {
                actionsHeader

                UCard(icon: "exclamationmark.triangle.fill", iconTint: AppPalette.Semantic.error) {
                    VStack(spacing: 12) {
                        Text(message)
                            .font(.subheadline)
                            .foregroundStyle(AppPalette.Neutral.textSecondary)
                            .multilineTextAlignment(.center)

                        UButton(
                            text: L10n.retry,
                            textColor: AppPalette.Primary.onMain,
                            backgroundColor: AppPalette.Primary.main,
                            cornerRadius: 12,
                            onPress: {
                                Task { await viewModel.refresh() }
                            }
                        )
                    }
                    .frame(maxWidth: .infinity)
                }
            }
            .padding(20)
        }
        .refreshable {
            await viewModel.refresh()
        }
    }
}

#Preview {
    NavigationStack {
        ZStack {
            AuthScreenBackground()
            Matchs()
        }
        .navigationTitle(L10n.matches)
    }
}
