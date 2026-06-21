//
//  MatchPrepareHubSection.swift
//  LeVestaire
//

import SwiftUI

struct MatchPrepareHubSection: View {
    @ObservedObject var viewModel: MatchDetailViewModel

    @State private var showsPublishConfirmation = false
    @State private var showsCompositionEditor = false
    @State private var compositionEditorReadOnly = false
    @State private var showsEditMatchSheet = false
    @State private var showsCancelConfirmation = false
    @State private var showsPostponeConfirmation = false

    private var match: MatchDetail? { viewModel.match }

    var body: some View {
        if let match {
            prepareHubContent(for: match)
        }
    }

    @ViewBuilder
    private func prepareHubContent(for match: MatchDetail) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            if viewModel.canEditMatchInfo {
                matchInfoSection(for: match)
            }

            if viewModel.showsAvailabilityManagement {
                availabilityManagementSection(for: match)
            }

            if match.composition != nil
                || match.capabilities.canManageComposition
                || match.isCompositionLocked {
                compositionSection(for: match)
            }

            if match.capabilities.canPublish || !viewModel.publishBlockerMessages.isEmpty {
                publishSection
            }

            if viewModel.canManageMatchLifecycle {
                lifecycleSection
            }
        }
        .sheet(isPresented: $showsCompositionEditor) {
            MatchCompositionEditorSheet(
                viewModel: viewModel,
                readOnly: compositionEditorReadOnly
            )
        }
        .sheet(isPresented: $showsEditMatchSheet) {
            EditMatchSheet(match: match) { updatedMatch in
                viewModel.updateMatchInfo(from: updatedMatch)
            }
        }
    }

    private func matchInfoSection(for match: MatchDetail) -> some View {
        UCard(
            title: L10n.text("matchInformation"),
            icon: "info.circle.fill",
            trailingHeader: {
                Button {
                    showsEditMatchSheet = true
                } label: {
                    Image(systemName: "square.and.pencil")
                        .font(.body.weight(.semibold))
                        .foregroundStyle(AppPalette.Primary.main)
                        .frame(width: 32, height: 32)
                        .background(
                            Circle()
                                .fill(AppPalette.Primary.soft.opacity(0.6))
                        )
                }
                .buttonStyle(.plain)
                .accessibilityLabel(L10n.editMatchInfo)
            }
        ) {
            VStack(alignment: .leading, spacing: 12) {
                if let opponentTeam = match.opponentTeam, !opponentTeam.isEmpty {
                    Label(opponentTeam, systemImage: "shield.fill")
                        .font(.subheadline)
                        .foregroundStyle(AppPalette.Neutral.textPrimary)
                }

                if let location = match.location, !location.isEmpty {
                    Label(location, systemImage: "mappin.and.ellipse")
                        .font(.caption)
                        .foregroundStyle(AppPalette.Neutral.textSecondary)
                }

                Label(match.date.formatted(date: .abbreviated, time: .omitted), systemImage: "calendar")
                    .font(.caption)
                    .foregroundStyle(AppPalette.Neutral.textSecondary)

                if let startTime = match.startTime, !startTime.isEmpty {
                    Label(startTime, systemImage: "clock")
                        .font(.caption)
                        .foregroundStyle(AppPalette.Neutral.textSecondary)
                }
            }
        }
    }

    private var lifecycleSection: some View {
        UCard(title: L10n.text("matchPrepareLifecycleTitle"), icon: "ellipsis.circle.fill") {
            VStack(alignment: .leading, spacing: 10) {
                Text(L10n.text("matchPrepareLifecycleHint"))
                    .font(.caption)
                    .foregroundStyle(AppPalette.Neutral.textSecondary)

                UButton(
                    text: L10n.postponeMatch,
                    textColor: AppPalette.Primary.main,
                    backgroundColor: AppPalette.Primary.soft,
                    cornerRadius: 12,
                    isFullWidth: true,
                    onPress: {
                        showsPostponeConfirmation = true
                    }
                )
                .confirmationDialog(
                    L10n.postponeMatch,
                    isPresented: $showsPostponeConfirmation,
                    titleVisibility: .visible
                ) {
                    Button(L10n.postponeMatch) {
                        Task { await viewModel.postponeMatch() }
                    }
                    Button(L10n.cancel, role: .cancel) {}
                } message: {
                    Text(L10n.postponeMatchConfirmation)
                }

                UButton(
                    text: L10n.cancelMatch,
                    textColor: AppPalette.Primary.onMain,
                    backgroundColor: AppPalette.Semantic.error,
                    cornerRadius: 12,
                    isFullWidth: true,
                    onPress: {
                        showsCancelConfirmation = true
                    }
                )
                .confirmationDialog(
                    L10n.cancelMatch,
                    isPresented: $showsCancelConfirmation,
                    titleVisibility: .visible
                ) {
                    Button(L10n.cancelMatch, role: .destructive) {
                        Task { await viewModel.cancelMatch() }
                    }
                    Button(L10n.cancel, role: .cancel) {}
                } message: {
                    Text(L10n.text("confirmCancelMatch"))
                }
            }
        }
    }

    private func availabilityManagementSection(for match: MatchDetail) -> some View {
        UCard(
            title: L10n.text("availabilityManagementTitle"),
            icon: "person.2.fill",
            stepNumber: 1
        ) {
            VStack(alignment: .leading, spacing: 12) {
                if let summary = availabilitySummary(for: match) {
                    Text(
                        L10n.availabilityResponsesSummary(
                            responded: summary.respondedCount,
                            total: summary.totalEligible
                        )
                    )
                    .font(.caption)
                    .foregroundStyle(AppPalette.Neutral.textSecondary)

                    Text(L10n.presentPlayersCount(summary.presentCount))
                        .font(.caption.weight(.medium))
                        .foregroundStyle(AppPalette.Primary.main)
                }

                Text(L10n.text("availabilityManagementHint"))
                    .font(.caption2)
                    .foregroundStyle(AppPalette.Neutral.textTertiary)

                if !viewModel.isLoadingAvailability, !viewModel.availability.isEmpty {
                    Text(L10n.selectablePlayersCount(viewModel.availability.count))
                        .font(.caption.weight(.medium))
                        .foregroundStyle(AppPalette.Neutral.textSecondary)
                }

                if viewModel.isLoadingAvailability, viewModel.availability.isEmpty {
                    ProgressView()
                        .frame(maxWidth: .infinity)
                } else if viewModel.availability.isEmpty {
                    Text(L10n.text("noPlayersAvailable"))
                        .font(.caption)
                        .foregroundStyle(AppPalette.Neutral.textSecondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                } else {
                    ForEach(viewModel.availability) { entry in
                        availabilityRow(entry)
                    }
                }
            }
        }
    }

    private func availabilitySummary(for match: MatchDetail) -> AvailabilitySummary? {
        if viewModel.isLoadingAvailability {
            return match.availabilitySummary ?? viewModel.availabilityBoardSummary
        }
        return viewModel.availabilityBoardSummary ?? match.availabilitySummary
    }

    private func availabilityRow(_ entry: MatchAvailabilityEntry) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(entry.displayName.isEmpty ? entry.playerId : entry.displayName)
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(AppPalette.Neutral.textPrimary)

                if entry.isGuest {
                    Text(L10n.text("guestLabel"))
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(AppPalette.Neutral.textSecondary)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(
                            Capsule()
                                .fill(AppPalette.Neutral.surface)
                        )
                }

                Spacer(minLength: 8)

                if !entry.isGuest {
                    Text(entry.status.displayName)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(AppPalette.Primary.main)
                }
            }

            if entry.isGuest {
                Text(L10n.text("availabilityGuestCompositionHint"))
                    .font(.caption2)
                    .foregroundStyle(AppPalette.Neutral.textTertiary)
            } else {
                if entry.source == .forcedByStaff {
                    Text(L10n.availabilityForcedByStaff)
                        .font(.caption2)
                        .foregroundStyle(AppPalette.Neutral.textTertiary)
                }

                HStack(spacing: 8) {
                    ForEach(MatchAvailabilityStatus.allCases, id: \.self) { status in
                        Button(status.displayName) {
                            Task {
                                await viewModel.forcePlayerAvailability(
                                    playerId: entry.availabilityRequestId,
                                    status: status
                                )
                            }
                        }
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(entry.status == status ? AppPalette.Primary.onMain : AppPalette.Primary.main)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 6)
                        .background(
                            Capsule()
                                .fill(entry.status == status ? AppPalette.Primary.main : AppPalette.Primary.soft)
                        )
                        .buttonStyle(.plain)
                        .disabled(viewModel.isSubmitting)
                    }
                }
            }
        }
        .padding(.vertical, 4)
    }

    private func compositionSection(for match: MatchDetail) -> some View {
        UCard(
            title: L10n.text("composition"),
            icon: "person.3.fill",
            stepNumber: 2
        ) {
            VStack(alignment: .leading, spacing: 12) {
                if let composition = match.composition {
                    MatchCompositionPreviewView(
                        composition: composition,
                        members: viewModel.editorMembers,
                        isCompositionLocked: match.isCompositionLocked,
                        style: .compact
                    )

                    if match.capabilities.canManageComposition, !match.isCompositionLocked {
                        UButton(
                            text: L10n.editMatchComposition,
                            textColor: AppPalette.Primary.main,
                            backgroundColor: AppPalette.Primary.soft,
                            cornerRadius: 12,
                            isFullWidth: true,
                            onPress: {
                                compositionEditorReadOnly = false
                                showsCompositionEditor = true
                            }
                        )

                        UButton(
                            text: L10n.text("lockComposition"),
                            textColor: AppPalette.Primary.onMain,
                            backgroundColor: AppPalette.Primary.main,
                            cornerRadius: 12,
                            isFullWidth: true,
                            onPress: {
                                Task { await viewModel.lockComposition() }
                            }
                        )
                    }
                } else if match.capabilities.canManageComposition {
                    Text(L10n.text("compositionCreatorPromptHint"))
                        .font(.caption)
                        .foregroundStyle(AppPalette.Neutral.textSecondary)

                    Text(L10n.selectablePlayersCount(viewModel.selectablePlayers.count))
                        .font(.caption.weight(.medium))
                        .foregroundStyle(AppPalette.Primary.main)

                    UButton(
                        text: L10n.text("createCompositionForMatch"),
                        textColor: AppPalette.Primary.onMain,
                        backgroundColor: AppPalette.Primary.main,
                        cornerRadius: 12,
                        isFullWidth: true,
                        onPress: {
                            compositionEditorReadOnly = false
                            showsCompositionEditor = true
                        }
                    )
                }
            }
        }
        .task {
            await viewModel.loadSelectablePlayers()
            await viewModel.loadTeamTemplates()
        }
    }

    private var publishSection: some View {
        UCard(
            title: L10n.publishMatchAction,
            icon: "checkmark.seal.fill",
            stepNumber: 3
        ) {
            VStack(alignment: .leading, spacing: 12) {
                ForEach(viewModel.publishBlockerMessages, id: \.self) { message in
                    Label(message, systemImage: "exclamationmark.triangle.fill")
                        .font(.caption)
                        .foregroundStyle(AppPalette.Semantic.warning)
                }

                UButton(
                    text: L10n.publishMatchAction,
                    textColor: AppPalette.Primary.onMain,
                    backgroundColor: AppPalette.Primary.main,
                    cornerRadius: 12,
                    isFullWidth: true,
                    onPress: {
                        showsPublishConfirmation = true
                    }
                )
                .opacity(viewModel.publishButtonEnabled ? 1 : 0.5)
                .disabled(!viewModel.publishButtonEnabled || viewModel.isSubmitting)
                .confirmationDialog(
                    L10n.publishMatchAction,
                    isPresented: $showsPublishConfirmation,
                    titleVisibility: .visible
                ) {
                    Button(L10n.text("publish")) {
                        Task { await viewModel.publishMatch() }
                    }
                    Button(L10n.cancel, role: .cancel) {}
                } message: {
                    Text(L10n.publishMatchConfirmation)
                }
            }
        }
    }
}

#if DEBUG
#Preview {
    MatchPrepareHubSection(viewModel: .preview(status: .draft))
        .padding()
        .teamPreviewEnvironment()
}
#endif
