//
//  TeamExpandableCard.swift
//  LeVestaire
//

import SwiftUI

struct TeamExpandableCard<CollapsedSummary: View, Content: View>: View {
    let title: String
    let icon: String
    let initiallyExpanded: Bool
    let isLoading: Bool
    @ViewBuilder let collapsedSummary: () -> CollapsedSummary
    @ViewBuilder let content: () -> Content

    @State private var isExpanded: Bool

    init(
        title: String,
        icon: String,
        initiallyExpanded: Bool = false,
        isLoading: Bool = false,
        @ViewBuilder collapsedSummary: @escaping () -> CollapsedSummary,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.title = title
        self.icon = icon
        self.initiallyExpanded = initiallyExpanded
        self.isLoading = isLoading
        self.collapsedSummary = collapsedSummary
        self.content = content
        _isExpanded = State(initialValue: initiallyExpanded)
    }

    var body: some View {
        UCard {
            VStack(alignment: .leading, spacing: isExpanded ? 16 : 12) {
                headerButton

                if isExpanded {
                    content()
                } else {
                    collapsedSummary()
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
                Image(systemName: icon)
                    .foregroundStyle(AppPalette.Primary.main)

                Text(title)
                    .font(.headline)
                    .foregroundStyle(AppPalette.Primary.dark)
                    .multilineTextAlignment(.leading)

                Spacer(minLength: 0)

                if isLoading {
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
        .accessibilityAddTraits(isExpanded ? .isSelected : [])
        .accessibilityHint(L10n.text(isExpanded ? "collapseSection" : "expandSection"))
    }
}

#if DEBUG
#Preview {
    TeamExpandableCard(
        title: "Insights saison",
        icon: "sparkles",
        initiallyExpanded: true,
        collapsedSummary: {
            Text("V · V · N · D · V — Hugo Petit")
                .font(.caption)
                .foregroundStyle(AppPalette.Neutral.textSecondary)
        },
        content: {
            Text("Contenu détaillé")
                .font(.subheadline)
        }
    )
    .padding()
    .teamPreviewEnvironment()
}
#endif
