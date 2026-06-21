//
//  Team.swift
//  LeVestaire
//
//  Created by Corentin Robert on 15/06/2026.
//

import SwiftUI

struct Team: View {
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
                    TeamHeroSection(viewModel: viewModel)

                    if viewModel.showsTeamDetailError, let errorMessage = viewModel.errorMessage {
                        TeamLoadErrorBanner(message: errorMessage) {
                            Task { await viewModel.retryTeamDetail() }
                        }
                    }

                    if viewModel.canManageTeam {
                        VStack(spacing: 12) {
                            TeamQuickActionsSection(viewModel: viewModel)
                            TeamInvitationsSection(viewModel: viewModel)
                        }
                    }

                    TeamKPISection(viewModel: viewModel)
                    TeamTabPicker(selection: $selectedTab)
                    tabContent
                        .animation(.easeInOut(duration: 0.2), value: selectedTab)
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
        .refreshable {
            await viewModel.refreshFromPullToRefresh(currentTab: selectedTab)
        }
        .sheet(item: $viewModel.guestPendingMerge) { guest in
            MergeGuestSheet(viewModel: viewModel, guest: guest)
                .presentationDetents([.medium, .large])
        }
        .sheet(item: $viewModel.activeSheet, onDismiss: {
            viewModel.editingComposition = nil
        }) { sheet in
            switch sheet {
            case .createTeam:
                CreateTeamSheet(viewModel: viewModel)
            case .settings:
                TeamSettingsSheet(viewModel: viewModel)
            case .invitePlayer:
                InvitePlayerSheet(viewModel: viewModel)
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
                get: { viewModel.invitationPendingCancellation != nil },
                set: { if !$0 { viewModel.invitationPendingCancellation = nil } }
            ),
            titleVisibility: .visible
        ) {
            Button(L10n.text("cancelInvitation"), role: .destructive) {
                Task { await viewModel.cancelInvitation() }
            }
            Button(L10n.cancel, role: .cancel) {
                viewModel.invitationPendingCancellation = nil
            }
        } message: {
            Text(L10n.text("cancelInvitationConfirm"))
        }
        .confirmationDialog(
            L10n.text("supprimerJoueur"),
            isPresented: Binding(
                get: { viewModel.memberPendingRemoval != nil },
                set: { if !$0 { viewModel.memberPendingRemoval = nil } }
            ),
            titleVisibility: .visible
        ) {
            Button(L10n.text("supprimerJoueur"), role: .destructive) {
                Task { await viewModel.removeMember() }
            }
            Button(L10n.cancel, role: .cancel) {
                viewModel.memberPendingRemoval = nil
            }
        } message: {
            if let member = viewModel.memberPendingRemoval {
                Text(L10n.format("confirmRemovePlayer", member.displayName))
            }
        }
        .confirmationDialog(
            L10n.deleteComposition,
            isPresented: Binding(
                get: { viewModel.compositionPendingDeletion != nil },
                set: { if !$0 { viewModel.compositionPendingDeletion = nil } }
            ),
            titleVisibility: .visible
        ) {
            Button(L10n.deleteComposition, role: .destructive) {
                Task { await viewModel.deletePendingComposition() }
            }
            Button(L10n.cancel, role: .cancel) {
                viewModel.compositionPendingDeletion = nil
            }
        } message: {
            if let composition = viewModel.compositionPendingDeletion {
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
        }
    }

    private var emptyTeamsCard: some View {
        UCard {
            TeamEmptyState(
                icon: "person.3",
                title: L10n.text("aucuneEquipeSelectionnee"),
                message: L10n.text("selectionnezEquipeOuCreez")
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
