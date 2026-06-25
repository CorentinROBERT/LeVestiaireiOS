//
//  JoinTeamSheet.swift
//  LeVestaire
//

import SwiftUI

struct JoinTeamSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    @ObservedObject var teamViewModel: TeamViewModel
    @StateObject private var viewModel = JoinTeamViewModel()

    init(teamViewModel: TeamViewModel) {
        self.teamViewModel = teamViewModel
    }

    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 20) {
                    descriptionText
                    searchModePicker
                    searchField
                    feedbackMessages
                    searchResultsSection
                    myRequestsSection
                }
                .padding(.horizontal, 20)
                .padding(.top, 8)
                .padding(.bottom, 24)
            }
            .background(AuthScreenBackground())
            .navigationTitle(L10n.text("joinTeam"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(L10n.close) { dismiss() }
                }
            }
        }
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
        .task {
            viewModel.refreshTeams = { [teamViewModel] in
                await teamViewModel.loadInitialData()
            }
            await viewModel.loadMyRequests()
        }
    }

    private var searchButtonIconColor: Color {
        colorScheme == .dark ? .black : .white
    }

    private var descriptionText: some View {
        Text(L10n.text("joinTeamDescription"))
            .font(.subheadline)
            .foregroundStyle(AppPalette.Neutral.textSecondary)
            .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var searchModePicker: some View {
        Picker(L10n.text("joinTeamSearchMode"), selection: $viewModel.searchMode) {
            ForEach(JoinTeamSearchMode.allCases) { mode in
                Text(mode.localizedTitle).tag(mode)
            }
        }
        .pickerStyle(.segmented)
    }

    private var searchField: some View {
        HStack(spacing: 12) {
            UGlassTextField(
                placeholder: viewModel.searchMode == .name
                    ? L10n.text("joinTeamSearchNamePlaceholder")
                    : L10n.text("joinTeamSearchIdPlaceholder"),
                icon: viewModel.searchMode == .name ? "magnifyingglass" : "number",
                text: $viewModel.searchQuery,
                autocapitalization: viewModel.searchMode == .name ? .words : .never
            )

            Button {
                Task { await viewModel.search() }
            } label: {
                Group {
                    if viewModel.isSearching {
                        ProgressView()
                            .tint(searchButtonIconColor)
                    } else {
                        Image(systemName: "arrow.right.circle.fill")
                            .font(.title2)
                            .foregroundStyle(searchButtonIconColor)
                    }
                }
                .frame(width: 44, height: 44)
                .background(AppPalette.Primary.main, in: Circle())
            }
            .buttonStyle(.plain)
            .disabled(viewModel.isSearching)
            .accessibilityLabel(L10n.text("search"))
        }
    }

    @ViewBuilder
    private var feedbackMessages: some View {
        if let error = viewModel.errorMessage {
            TeamSectionErrorText(message: error)
        }

        if let success = viewModel.successMessage {
            Text(success)
                .font(.caption)
                .foregroundStyle(AppPalette.Secondary.mint)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    @ViewBuilder
    private var searchResultsSection: some View {
        if !viewModel.searchResults.isEmpty {
            VStack(alignment: .leading, spacing: 12) {
                Text(L10n.text("joinTeamResults"))
                    .font(.headline)
                    .foregroundStyle(AppPalette.Primary.dark)

                ForEach(viewModel.searchResults) { team in
                    teamResultCard(team)
                }
            }
        }
    }

    @ViewBuilder
    private var myRequestsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(L10n.text("myJoinRequests"))
                    .font(.headline)
                    .foregroundStyle(AppPalette.Primary.dark)

                if viewModel.isLoadingMyRequests {
                    ProgressView()
                        .controlSize(.small)
                }
            }

            if viewModel.pendingJoinRequests.isEmpty, !viewModel.isLoadingMyRequests {
                Text(L10n.text("noPendingJoinRequests"))
                    .font(.caption)
                    .foregroundStyle(AppPalette.Neutral.textSecondary)
            } else {
                ForEach(viewModel.pendingJoinRequests) { request in
                    myRequestRow(request)
                }
            }
        }
    }

    private func teamResultCard(_ team: TeamSearchResult) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top, spacing: 12) {
                teamLogo(for: team)

                VStack(alignment: .leading, spacing: 4) {
                    Text(team.name)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(AppPalette.Neutral.textPrimary)

                    if !team.subtitle.isEmpty {
                        Text(team.subtitle)
                            .font(.caption)
                            .foregroundStyle(AppPalette.Neutral.textSecondary)
                    }
                }

                Spacer(minLength: 0)
            }

            if team.isMember {
                statusBadge(
                    text: L10n.text("alreadyTeamMember"),
                    color: AppPalette.Neutral.textSecondary
                )
            } else if team.hasPendingJoinRequest {
                statusBadge(
                    text: L10n.text("joinRequestPending"),
                    color: AppPalette.Semantic.warning
                )
            } else {
                joinRequestForm(for: team)
            }
        }
        .padding(12)
        .glassEffect(.regular, in: .rect(cornerRadius: 14))
    }

    private func joinRequestForm(for team: TeamSearchResult) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(L10n.text("joinRequestMessageOptional"))
                .font(.caption)
                .foregroundStyle(AppPalette.Neutral.textSecondary)

            TextEditor(text: viewModel.messageBinding(for: team.id))
                .frame(minHeight: 72)
                .padding(8)
                .scrollContentBackground(.hidden)
                .background(AppPalette.Neutral.surface.opacity(0.35), in: RoundedRectangle(cornerRadius: 12))

            Text(
                L10n.format(
                    "joinRequestMessageCounter",
                    viewModel.requestMessages[team.id, default: ""].count,
                    JoinTeamViewModel.messageMaxLength
                )
            )
            .font(.caption2)
            .foregroundStyle(AppPalette.Neutral.textSecondary)

            Button {
                Task { _ = await viewModel.submitJoinRequest(for: team) }
            } label: {
                Text(L10n.text("requestToJoin"))
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(AppPalette.Primary.main, in: RoundedRectangle(cornerRadius: 14))
                    .overlay {
                        if viewModel.isSubmitting(teamId: team.id) {
                            ProgressView()
                                .tint(.white)
                        }
                    }
            }
            .buttonStyle(.plain)
            .disabled(viewModel.isSubmitting(teamId: team.id))
        }
    }

    private func myRequestRow(_ request: TeamJoinRequest) -> some View {
        HStack(alignment: .top, spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(request.resolvedTeamName)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(AppPalette.Neutral.textPrimary)

                Text(request.status.localizedLabel)
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(AppPalette.Semantic.warning)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(AppPalette.Semantic.warning.opacity(0.12))
                    .clipShape(Capsule())

                if let message = request.message?.trimmingCharacters(in: .whitespacesAndNewlines),
                   !message.isEmpty {
                    Text(message)
                        .font(.caption)
                        .foregroundStyle(AppPalette.Neutral.textSecondary)
                }
            }

            Spacer(minLength: 0)

            Button(L10n.cancel) {
                Task { await viewModel.cancelJoinRequest(request) }
            }
            .font(.caption.weight(.semibold))
            .foregroundStyle(AppPalette.Secondary.coral)
            .disabled(viewModel.isCancelling(requestId: request.id))
        }
        .padding(12)
        .glassEffect(.regular, in: .rect(cornerRadius: 14))
    }

    @ViewBuilder
    private func teamLogo(for team: TeamSearchResult) -> some View {
        if let logoUrl = RemoteMediaURL.resolve(team.logoUrl),
           let url = URL(string: logoUrl) {
            CachedRemoteImage(url: url) { image in
                image
                    .resizable()
                    .scaledToFill()
                    .frame(width: 48, height: 48)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            } placeholder: {
                teamLogoPlaceholder
            }
        } else {
            teamLogoPlaceholder
        }
    }

    private var teamLogoPlaceholder: some View {
        RoundedRectangle(cornerRadius: 12)
            .fill(AppPalette.Primary.soft)
            .frame(width: 48, height: 48)
            .overlay {
                Image(systemName: "person.3.fill")
                    .font(.body)
                    .foregroundStyle(AppPalette.Primary.main)
            }
    }

    private func statusBadge(text: String, color: Color) -> some View {
        Text(text)
            .font(.caption.weight(.semibold))
            .foregroundStyle(color)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(color.opacity(0.12), in: Capsule())
    }
}

#if DEBUG
#Preview {
    JoinTeamSheet(teamViewModel: .preview())
        .teamPreviewEnvironment()
}
#endif
