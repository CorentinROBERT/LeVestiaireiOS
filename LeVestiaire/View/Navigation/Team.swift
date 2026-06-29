//
//  Team.swift
//  LeVestaire
//
//  Created by Corentin Robert on 15/06/2026.
//

import SwiftUI

struct Team: View {
    @EnvironmentObject private var mainTabViewModel: MainTabViewModel
    @StateObject private var viewModel: TeamViewModel
    @State private var selectedTab: TeamContentTab = .roster

    private let loadsDataOnAppear: Bool

    init() {
        _viewModel = StateObject(wrappedValue: TeamViewModel())
        loadsDataOnAppear = true
    }

    init(previewViewModel: TeamViewModel) {
        _viewModel = StateObject(wrappedValue: previewViewModel)
        loadsDataOnAppear = false
    }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 20) {
                if viewModel.isLoading, !viewModel.hasTeams {
                    ProgressView(L10n.loading)
                        .frame(maxWidth: .infinity)
                        .padding(.top, 40)
                } else if let errorMessage = viewModel.errorMessage, !viewModel.hasTeams {
                    teamErrorState(message: errorMessage)
                } else if viewModel.hasTeams {
                    Group {
                        TeamHeroSection(viewModel: viewModel)

                        if viewModel.showsTeamDetailError, let errorMessage = viewModel.errorMessage {
                            TeamLoadErrorBanner(message: errorMessage) {
                                Task { await viewModel.retryTeamDetail() }
                            }
                        }

                        if viewModel.canManageTeam {
                            VStack(spacing: 12) {
                                TeamQuickActionsSection(viewModel: viewModel)
                                TeamJoinRequestsSection(viewModel: viewModel)
                                TeamInvitationsSection(viewModel: viewModel)
                            }
                        }

                        TeamTabPicker(selection: $selectedTab)
                        tabContent
                            .animation(.easeInOut(duration: 0.2), value: selectedTab)
                    }
                    .accessibilityIdentifier(AccessibilityID.Team.shell)
                } else {
                    createTeamCard
                    emptyTeamsCard
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 8)
            .padding(.bottom, 24)
        }
        .overlay(alignment: .bottom) {
            if let toastMessage = viewModel.toastMessage {
                TeamToastBanner(message: toastMessage)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .animation(.easeInOut(duration: 0.25), value: viewModel.toastMessage)
        .task {
            guard loadsDataOnAppear else { return }
            await viewModel.loadInitialData()
            await viewModel.loadTabContentIfNeeded(selectedTab)
        }
        .onChange(of: selectedTab) { _, tab in
            Task { await viewModel.loadTabContentIfNeeded(tab) }
        }
        .onChange(of: viewModel.toastMessage) { _, message in
            guard message != nil else { return }
            Task {
                try? await Task.sleep(nanoseconds: 2_500_000_000)
                if viewModel.toastMessage == message {
                    viewModel.toastMessage = nil
                }
            }
        }
        .onChange(of: mainTabViewModel.pendingTeamId) { _, teamId in
            guard let teamId, !teamId.isEmpty else { return }
            Task {
                await viewModel.selectTeamFromNotification(id: teamId)
                mainTabViewModel.clearPendingTeamNavigation()
            }
        }
        .refreshable {
            await viewModel.refreshFromPullToRefresh(currentTab: selectedTab)
        }
        .sheet(item: Binding(
            get: { viewModel.rosterViewModel.guestPendingMerge },
            set: { viewModel.rosterViewModel.guestPendingMerge = $0 }
        )) { guest in
            MergeGuestSheet(viewModel: viewModel, guest: guest)
                .presentationDetents([.medium, .large])
        }
        .sheet(item: $viewModel.activeSheet, onDismiss: {
            viewModel.compositionsViewModel.editingComposition = nil
        }) { sheet in
            switch sheet {
            case .createTeam:
                CreateTeamSheet(viewModel: viewModel)
            case .joinTeam:
                JoinTeamSheet(teamViewModel: viewModel)
            case .settings:
                TeamSettingsSheet(viewModel: viewModel)
            case .invitePlayer:
                InvitePlayerSheet(viewModel: viewModel)
            case .shareTeamInvite:
                TeamInviteShareSheet(viewModel: viewModel)
            case .addGuest:
                AddGuestSheet(viewModel: viewModel)
            case .compositionEditor:
                CompositionEditorSheet(
                    viewModel: viewModel,
                    composition: sheet.composition
                )
                .presentationDetents([.large])
            }
        }
        .alert(
            L10n.team,
            isPresented: Binding(
                get: { viewModel.alertMessage != nil },
                set: { if !$0 { viewModel.alertMessage = nil } }
            )
        ) {
            Button(L10n.ok, role: .cancel) {}
        } message: {
            Text(viewModel.alertMessage ?? "")
        }
        .confirmationDialog(
            L10n.text("cancelInvitation"),
            isPresented: Binding(
                get: { viewModel.invitationsViewModel.invitationPendingCancellation != nil },
                set: { if !$0 { viewModel.invitationsViewModel.invitationPendingCancellation = nil } }
            ),
            titleVisibility: .visible
        ) {
            Button(L10n.text("cancelInvitation"), role: .destructive) {
                Task { await viewModel.invitationsViewModel.cancelInvitation() }
            }
            Button(L10n.cancel, role: .cancel) {
                viewModel.invitationsViewModel.invitationPendingCancellation = nil
            }
        } message: {
            Text(L10n.text("cancelInvitationConfirm"))
        }
        .confirmationDialog(
            L10n.deleteComposition,
            isPresented: Binding(
                get: { viewModel.compositionsViewModel.compositionPendingDeletion != nil },
                set: { if !$0 { viewModel.compositionsViewModel.compositionPendingDeletion = nil } }
            ),
            titleVisibility: .visible
        ) {
            Button(L10n.deleteComposition, role: .destructive) {
                Task { await viewModel.compositionsViewModel.deletePendingComposition() }
            }
            Button(L10n.cancel, role: .cancel) {
                viewModel.compositionsViewModel.compositionPendingDeletion = nil
            }
        } message: {
            if let composition = viewModel.compositionsViewModel.compositionPendingDeletion {
                Text(L10n.format("confirmDeleteComposition", composition.name))
            }
        }
    }

    @ViewBuilder
    private var tabContent: some View {
        switch selectedTab {
        case .roster:
            TeamPlayersSection(viewModel: viewModel)
        case .stats:
            TeamStatsSection(viewModel: viewModel)
        case .rankings:
            TeamRankingsSection(viewModel: viewModel)
        case .compositions:
            TeamCompositionsSection(viewModel: viewModel)
        }
    }

    private var createTeamCard: some View {
        UCard(title: L10n.text("monEquipe"), icon: "person.3.fill") {
            VStack(spacing: 12) {
                UButton(
                    text: L10n.text("creerUneEquipe"),
                    textColor: AppPalette.Primary.onMain,
                    backgroundColor: AppPalette.Primary.main,
                    cornerRadius: 18,
                    isFullWidth: true,
                    leadingIcon: "plus.circle.fill",
                    onPress: {
                        viewModel.activeSheet = .createTeam
                    }
                )

                UButton(
                    text: L10n.text("joinTeam"),
                    textColor: AppPalette.Primary.main,
                    backgroundColor: AppPalette.Primary.soft.opacity(0.45),
                    cornerRadius: 18,
                    isFullWidth: true,
                    leadingIcon: "magnifyingglass",
                    onPress: {
                        viewModel.activeSheet = .joinTeam
                    }
                )
            }
        }
    }

    private var emptyTeamsCard: some View {
        UCard {
            TeamEmptyState(
                icon: "person.3",
                title: L10n.text("aucuneEquipeSelectionnee"),
                message: L10n.text("selectionnezEquipeOuCreez"),
                actionTitle: L10n.text("joinTeam"),
                action: {
                    viewModel.activeSheet = .joinTeam
                }
            )
        }
    }

    private func teamErrorState(message: String) -> some View {
        VStack(spacing: 16) {
            TeamEmptyState(
                icon: "exclamationmark.triangle",
                title: message,
                actionTitle: L10n.retry,
                action: {
                    Task { await viewModel.loadInitialData() }
                }
            )
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 40)
    }
}

#if DEBUG
#Preview("Équipe chargée") {
    Team(previewViewModel: .preview())
        .teamPreviewEnvironment()
}

#Preview("Sans équipe") {
    Team(previewViewModel: .previewEmpty())
        .teamPreviewEnvironment()
}
#endif
