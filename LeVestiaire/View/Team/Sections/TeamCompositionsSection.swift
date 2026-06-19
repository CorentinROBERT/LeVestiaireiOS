//
//  TeamCompositionsSection.swift
//  LeVestaire
//

import SwiftUI

struct TeamCompositionsSection: View {
    @ObservedObject var viewModel: TeamViewModel

    var body: some View {
        UCard(
            title: L10n.text("compositions"),
            icon: "sportscourt.fill",
            trailingHeader: {
                if viewModel.canManageTeam {
                    Button {
                        viewModel.openCompositionEditor(for: nil)
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.title3)
                            .foregroundStyle(AppPalette.Primary.main)
                    }
                    .buttonStyle(.plain)
                }
            }
        ) {
            if viewModel.isRefreshingTeam, viewModel.compositions.isEmpty {
                TeamLoadingPlaceholder()
            } else if let error = viewModel.compositionsLoadError {
                TeamSectionErrorView(message: error) {
                    Task { await viewModel.retryCompositions() }
                }
            } else if viewModel.compositions.isEmpty {
                TeamEmptyState(
                    icon: "sportscourt",
                    title: L10n.text("aucuneCompositionCreee"),
                    message: L10n.text("compositionsDescription"),
                    actionTitle: viewModel.canManageTeam ? L10n.text("creerComposition") : nil,
                    action: viewModel.canManageTeam ? { viewModel.openCompositionEditor(for: nil) } : nil
                )
            } else {
                VStack(spacing: 12) {
                    ForEach(viewModel.compositions) { composition in
                        compositionRow(composition)
                    }
                }
            }
        }
    }

    @ViewBuilder
    private func compositionRow(_ composition: TeamComposition) -> some View {
        Button {
            viewModel.openCompositionEditor(for: composition)
        } label: {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(composition.name)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(AppPalette.Neutral.textPrimary)

                    Text(composition.formation ?? L10n.text("formationNotDefined"))
                        .font(.caption)
                        .foregroundStyle(AppPalette.Neutral.textSecondary)

                    if composition.hasAlternativeFormations {
                        compositionAlternativesBadge(count: composition.alternativeCount)
                    }
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(AppPalette.Neutral.textSecondary)
            }
            .contentShape(Rectangle())
            .padding(12)
            .glassEffect(.regular, in: .rect(cornerRadius: 14))
        }
        .buttonStyle(.plain)
        .contextMenu {
            if viewModel.canManageTeam {
                Button(L10n.text("edit")) {
                    viewModel.openCompositionEditor(for: composition)
                }
                Button(L10n.text("delete"), role: .destructive) {
                    viewModel.confirmDeleteComposition(composition)
                }
            }
        }
    }

    private func compositionAlternativesBadge(count: Int) -> some View {
        HStack(spacing: 4) {
            Image(systemName: "square.stack.3d.up.fill")
                .font(.caption2)
            Text(L10n.compositionAlternativesLabel(count: count))
                .font(.caption2.weight(.medium))
        }
        .foregroundStyle(AppPalette.Primary.main)
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background {
            Capsule()
                .fill(AppPalette.Primary.soft)
        }
        .accessibilityLabel(L10n.compositionAlternativesLabel(count: count))
    }
}
