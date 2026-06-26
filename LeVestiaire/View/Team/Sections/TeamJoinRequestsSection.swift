//
//  TeamJoinRequestsSection.swift
//  LeVestaire
//

import SwiftUI

struct TeamJoinRequestsSection: View {
    @ObservedObject var viewModel: TeamViewModel
    @ObservedObject var joinRequestsViewModel: TeamJoinRequestsViewModel
    @State private var isExpanded = false

    init(viewModel: TeamViewModel) {
        self.viewModel = viewModel
        self.joinRequestsViewModel = viewModel.joinRequestsViewModel
    }

    var body: some View {
        UCard {
            VStack(alignment: .leading, spacing: isExpanded ? 16 : 12) {
                headerButton

                if isExpanded {
                    expandedContent
                } else {
                    collapsedSummary
                }
            }
        }
    }

    private var headerButton: some View {
        Button {
            withAnimation(.easeInOut(duration: 0.25)) {
                isExpanded.toggle()
            }
            TeamHaptics.lightImpact()
        } label: {
            HStack(spacing: 10) {
                Image(systemName: "person.crop.circle.badge.plus")
                    .foregroundStyle(AppPalette.Primary.main)

                Text(L10n.format("joinRequestsTitle", joinRequestsViewModel.pendingCount))
                    .font(.headline)
                    .foregroundStyle(AppPalette.Primary.dark)

                Spacer(minLength: 0)

                if joinRequestsViewModel.isLoading {
                    ProgressView()
                        .controlSize(.small)
                }

                Image(systemName: "chevron.down")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(AppPalette.Neutral.textSecondary)
                    .rotationEffect(.degrees(isExpanded ? 180 : 0))
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.fullTap)
    }

    @ViewBuilder
    private var collapsedSummary: some View {
        if let error = joinRequestsViewModel.loadError {
            TeamSectionErrorText(message: error)
        } else if joinRequestsViewModel.isLoading {
            Text(L10n.loading)
                .font(.caption)
                .foregroundStyle(AppPalette.Neutral.textSecondary)
        } else if joinRequestsViewModel.pendingCount == 0 {
            Text(L10n.text("noJoinRequests"))
                .font(.caption)
                .foregroundStyle(AppPalette.Neutral.textSecondary)
        } else {
            Text(L10n.format("pendingJoinRequestsCount", joinRequestsViewModel.pendingCount))
                .font(.caption)
                .foregroundStyle(AppPalette.Neutral.textSecondary)
        }
    }

    @ViewBuilder
    private var expandedContent: some View {
        if joinRequestsViewModel.isLoading {
            TeamLoadingPlaceholder(rowCount: 2)
        } else if let error = joinRequestsViewModel.loadError {
            TeamSectionErrorView(message: error) {
                Task { await joinRequestsViewModel.retry() }
            }
        } else if joinRequestsViewModel.joinRequests.isEmpty {
            TeamEmptyState(
                icon: "person.crop.circle.badge.plus",
                title: L10n.text("noJoinRequests"),
                message: L10n.text("noJoinRequestsMessage")
            )
        } else {
            VStack(spacing: 12) {
                ForEach(joinRequestsViewModel.joinRequests) { request in
                    requestRow(request)
                }
            }
        }
    }

    private func requestRow(_ request: TeamJoinRequest) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .top, spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(request.applicantDisplayName)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(AppPalette.Neutral.textPrimary)

                    Text(request.status.localizedLabel)
                        .font(.caption2.weight(.semibold))
                    .foregroundStyle(AppPalette.Semantic.warning)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(AppPalette.Semantic.warning.opacity(0.12))
                        .clipShape(Capsule())
                }

                Spacer(minLength: 0)
            }

            if let message = request.message?.trimmingCharacters(in: .whitespacesAndNewlines),
               !message.isEmpty {
                Text(message)
                    .font(.caption)
                    .foregroundStyle(AppPalette.Neutral.textSecondary)
            }

            HStack(spacing: 12) {
                Button(L10n.text("reject")) {
                    Task { await joinRequestsViewModel.reviewRequest(request, action: .reject) }
                }
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(AppPalette.Secondary.coral)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .background(AppPalette.Secondary.coral.opacity(0.12), in: RoundedRectangle(cornerRadius: 12))
                .disabled(joinRequestsViewModel.isReviewing(request.id))

                Button(L10n.text("approve")) {
                    Task { await joinRequestsViewModel.reviewRequest(request, action: .approve) }
                }
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .background(AppPalette.Primary.main, in: RoundedRectangle(cornerRadius: 12))
                .disabled(joinRequestsViewModel.isReviewing(request.id))
            }
        }
        .padding(12)
        .glassEffect(.regular, in: .rect(cornerRadius: 14))
    }
}

#if DEBUG
#Preview {
    TeamJoinRequestsSection(viewModel: .preview())
        .padding()
        .teamPreviewEnvironment()
}
#endif
