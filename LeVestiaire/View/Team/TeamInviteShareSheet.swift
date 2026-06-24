//
//  TeamInviteShareSheet.swift
//  LeVestaire
//

import SwiftUI

struct TeamInviteShareSheet: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var viewModel: TeamViewModel

    @State private var showsCopiedFeedback = false

    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 20) {
                    if viewModel.isLoadingTeamInviteLink, viewModel.teamInviteLink == nil {
                        ProgressView(L10n.loading)
                            .frame(maxWidth: .infinity)
                            .padding(.top, 40)
                    } else if let link = viewModel.teamInviteLink {
                        inviteContent(link)
                    } else if let error = viewModel.teamInviteLinkError {
                        errorState(message: error)
                    }
                }
                .padding(20)
            }
            .navigationTitle(L10n.text("shareTeamInviteLink"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(L10n.close) { dismiss() }
                }
            }
            .task {
                await viewModel.loadTeamInviteLink()
            }
        }
    }

    @ViewBuilder
    private func inviteContent(_ link: TeamInviteLink) -> some View {
        UCard(title: viewModel.selectedTeam?.name ?? L10n.team, icon: "link") {
            VStack(alignment: .leading, spacing: 16) {
                if let code = link.code, !code.isEmpty {
                    infoRow(title: L10n.text("teamInviteCodeLabel"), value: code)
                }

                if let shareUrl = link.shareUrl, !shareUrl.isEmpty {
                    infoRow(title: L10n.text("teamInviteLinkLabel"), value: shareUrl)
                }

                if let expiresAt = link.expiresAt, !expiresAt.isEmpty {
                    infoRow(title: L10n.text("teamInviteExpiresLabel"), value: expiresAt)
                }

                Text(L10n.text("teamInviteShareDescription"))
                    .font(.caption)
                    .foregroundStyle(AppPalette.Neutral.textSecondary)
            }
        }

        VStack(spacing: 12) {
            if let shareUrl = link.shareUrl, let url = URL(string: shareUrl) {
                ShareLink(item: url) {
                    shareButtonLabel(L10n.text("shareTeamInviteLink"))
                }
                .buttonStyle(.plain)
            }

            UButton(
                text: showsCopiedFeedback ? L10n.text("teamInviteLinkCopied") : L10n.text("copyTeamInviteLink"),
                textColor: AppPalette.Primary.onMain,
                backgroundColor: AppPalette.Primary.main,
                cornerRadius: 14,
                isFullWidth: true,
                trailingIcon: showsCopiedFeedback ? "checkmark" : "doc.on.doc",
                onPress: {
                    copyShareURL(link.shareUrl)
                }
            )

            UButton(
                text: L10n.text("teamInviteRegenerate"),
                textColor: AppPalette.Primary.main,
                backgroundColor: AppPalette.Neutral.surface,
                cornerRadius: 14,
                isFullWidth: true,
                trailingIcon: "arrow.clockwise",
                onPress: {
                    Task { await viewModel.regenerateTeamInviteLink() }
                }
            )
            .disabled(viewModel.isLoadingTeamInviteLink)
        }
    }

    private func infoRow(title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption.weight(.semibold))
                .foregroundStyle(AppPalette.Neutral.textSecondary)
            Text(value)
                .font(.subheadline)
                .foregroundStyle(AppPalette.Neutral.textPrimary)
                .textSelection(.enabled)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func shareButtonLabel(_ title: String) -> some View {
        HStack {
            Text(title)
                .font(.subheadline.weight(.semibold))
            Spacer()
            Image(systemName: "square.and.arrow.up")
        }
        .foregroundStyle(AppPalette.Primary.onMain)
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .frame(maxWidth: .infinity)
        .background(AppPalette.Secondary.mint, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

    private func copyShareURL(_ shareUrl: String?) {
        guard let shareUrl, !shareUrl.isEmpty else { return }
        UIPasteboard.general.string = shareUrl
        showsCopiedFeedback = true
        TeamHaptics.success()

        Task {
            try? await Task.sleep(nanoseconds: 2_000_000_000)
            showsCopiedFeedback = false
        }
    }

    private func errorState(message: String) -> some View {
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
                        Task { await viewModel.loadTeamInviteLink() }
                    }
                )
            }
            .frame(maxWidth: .infinity)
        }
    }
}

#if DEBUG
#Preview {
    TeamInviteShareSheet(viewModel: .preview())
        .teamPreviewEnvironment()
}
#endif
