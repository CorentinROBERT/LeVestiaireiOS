//
//  MatchCompositionPreviewView.swift
//  LeVestaire
//

import SwiftUI

enum MatchCompositionPreviewStyle {
    case compact
    case full
}

struct MatchCompositionPreviewView: View {
    let composition: TeamComposition
    let members: [TeamMember]
    let isCompositionLocked: Bool
    var style: MatchCompositionPreviewStyle = .compact

    @State private var selectedTabId = ""

    private var tabs: [CompositionTabDraft] {
        CompositionTabDraft.from(composition: composition)
    }

    private var selectedTab: CompositionTabDraft? {
        tabs.first { $0.id == selectedTabId }
    }

    private var isCompact: Bool {
        style == .compact
    }

    private var showsAlternativeTabs: Bool {
        composition.hasAlternativeFormations || tabs.count > 1
    }

    var body: some View {
        VStack(alignment: .leading, spacing: isCompact ? 10 : 16) {
            headerSection

            if showsAlternativeTabs {
                tabSelector
            }

            if let tab = selectedTab {
                formationPanel(for: tab)
            } else if members.isEmpty {
                ProgressView(L10n.loading)
                    .frame(
                        maxWidth: .infinity,
                        minHeight: isCompact ? FormationFieldView.compactFieldHeight : 200
                    )
            }
        }
        .onAppear(perform: bootstrapSelection)
        .onChange(of: composition.id) { _, _ in
            bootstrapSelection()
        }
        .onChange(of: composition.alternativeCount) { _, _ in
            bootstrapSelection()
        }
    }

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: isCompact ? 6 : 10) {
            if !isCompact {
                Text(composition.name)
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(AppPalette.Neutral.textPrimary)
            } else {
                HStack(alignment: .firstTextBaseline) {
                    Text(composition.name)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(AppPalette.Neutral.textPrimary)
                        .lineLimit(1)

                    Spacer(minLength: 8)

                    if let tab = selectedTab {
                        Text(tab.formationDisplayName)
                            .font(.caption2.weight(.medium))
                            .foregroundStyle(AppPalette.Neutral.textSecondary)
                            .lineLimit(1)
                    }
                }
            }

            HStack(spacing: 8) {
                if isCompositionLocked {
                    Label(L10n.text("compositionValidated"), systemImage: "lock.fill")
                        .font(isCompact ? .caption2.weight(.semibold) : .caption.weight(.semibold))
                        .foregroundStyle(AppPalette.Semantic.success)
                        .padding(.horizontal, isCompact ? 8 : 10)
                        .padding(.vertical, isCompact ? 4 : 6)
                        .background {
                            Capsule()
                                .fill(AppPalette.Semantic.success.opacity(0.12))
                        }
                }

                if composition.hasAlternativeFormations {
                    CompositionAlternativesBadge(count: composition.alternativeCount)
                }
            }

            if !isCompact, showsAlternativeTabs {
                Text(L10n.compositionViewerAlternativesHint)
                    .font(.caption)
                    .foregroundStyle(AppPalette.Neutral.textSecondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var tabSelector: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: isCompact ? 6 : 8) {
                ForEach(tabs) { tab in
                    Button {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            selectedTabId = tab.id
                        }
                    } label: {
                        if isCompact {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(tab.displayLabel)
                                    .font(.caption2.weight(.semibold))
                                    .lineLimit(1)

                                Text(tab.formationDisplayName)
                                    .font(.system(size: 9, weight: .medium))
                                    .lineLimit(1)
                                    .opacity(0.85)
                            }
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background {
                                Capsule()
                                    .fill(
                                        selectedTabId == tab.id
                                            ? AppPalette.Primary.main
                                            : AppPalette.Neutral.surface
                                    )
                            }
                            .foregroundStyle(
                                selectedTabId == tab.id
                                    ? AppPalette.Primary.onMain
                                    : AppPalette.Neutral.textPrimary
                            )
                        } else {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(tab.displayLabel)
                                    .font(.caption.weight(.semibold))
                                    .lineLimit(1)

                                Text(tab.formationDisplayName)
                                    .font(.caption2)
                                    .opacity(selectedTabId == tab.id ? 0.9 : 0.7)
                                    .lineLimit(1)
                            }
                            .padding(.horizontal, 14)
                            .padding(.vertical, 10)
                            .background {
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(
                                        selectedTabId == tab.id
                                            ? AppPalette.Primary.main
                                            : AppPalette.Neutral.surface
                                    )
                            }
                            .foregroundStyle(
                                selectedTabId == tab.id
                                    ? AppPalette.Primary.onMain
                                    : AppPalette.Neutral.textPrimary
                            )
                        }
                    }
                    .buttonStyle(.fullTap)
                }
            }
        }
    }

    @ViewBuilder
    private func formationPanel(for tab: CompositionTabDraft) -> some View {
        let resolvedMembers = CompositionDisplayMemberResolver.members(
            for: tab,
            in: composition,
            pool: members
        )
        let substituteEntries = CompositionDisplayMemberResolver.substituteEntries(
            for: tab,
            in: composition,
            pool: members
        )

        VStack(alignment: .leading, spacing: isCompact ? 8 : 14) {
            if !isCompact {
                formationSummaryRow(for: tab)
            } else {
                compactSummaryRow(for: tab)
            }

            if resolvedMembers.isEmpty, members.isEmpty {
                ProgressView(L10n.loading)
                    .frame(maxWidth: .infinity, minHeight: isCompact ? FormationFieldView.compactFieldHeight : 220)
            } else {
                VStack(alignment: .leading, spacing: isCompact ? 8 : 14) {
                    FormationFieldView(
                        formationKey: tab.formationKey,
                        members: resolvedMembers,
                        assignments: tab.starterAssignments,
                        onPositionTapped: { _ in },
                        interactive: false,
                        compact: isCompact,
                        captainMemberKey: tab.isMain ? tab.sanitizedCaptainMemberKey() : nil
                    )

                    SubstitutesBenchMiniView(
                        entries: substituteEntries,
                        captainMemberKey: tab.isMain ? tab.sanitizedCaptainMemberKey() : nil
                    )
                }
                .frame(minHeight: isCompact ? Self.compactPanelHeight : nil, alignment: .top)
            }

            if !isCompact,
               !tab.tacticalNotes.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                tacticalNotesSection(tab.tacticalNotes)
            }
        }
    }

    private static let compactPanelHeight: CGFloat = FormationFieldView.compactFieldHeight + 52

    private func compactSummaryRow(for tab: CompositionTabDraft) -> some View {
        HStack(spacing: 6) {
            Text(L10n.compositionStartersCount(tab.filledStarterCount))
                .font(.caption2.weight(.medium))
                .foregroundStyle(AppPalette.Primary.main)

            if tab.filledSubstituteCount > 0 {
                Text("·")
                    .font(.caption2)
                    .foregroundStyle(AppPalette.Neutral.textTertiary)
                Text(L10n.compositionSubstitutesCount(tab.filledSubstituteCount))
                    .font(.caption2.weight(.medium))
                    .foregroundStyle(AppPalette.Neutral.textSecondary)
            }
        }
    }

    private func formationSummaryRow(for tab: CompositionTabDraft) -> some View {
        HStack(spacing: 8) {
            Label(tab.formationDisplayName, systemImage: "sportscourt.fill")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(AppPalette.Neutral.textPrimary)

            Spacer(minLength: 8)

            Text(L10n.compositionStartersCount(tab.filledStarterCount))
                .font(.caption.weight(.medium))
                .foregroundStyle(AppPalette.Primary.main)

            if tab.filledSubstituteCount > 0 {
                Text("·")
                    .foregroundStyle(AppPalette.Neutral.textTertiary)
                Text(L10n.compositionSubstitutesCount(tab.filledSubstituteCount))
                    .font(.caption.weight(.medium))
                    .foregroundStyle(AppPalette.Neutral.textSecondary)
            }
        }
        .padding(12)
        .glassEffect(.regular, in: .rect(cornerRadius: 14))
    }

    private func tacticalNotesSection(_ notes: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(L10n.text("tacticalNotes"))
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(AppPalette.Neutral.textPrimary)

            Text(notes)
                .font(.subheadline)
                .foregroundStyle(AppPalette.Neutral.textSecondary)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(12)
        .glassEffect(.regular, in: .rect(cornerRadius: 14))
    }

    private func bootstrapSelection() {
        let loaded = tabs
        if loaded.contains(where: { $0.id == selectedTabId }) {
            return
        }
        selectedTabId = loaded.first?.id ?? ""
    }
}

struct SubstitutesBenchMiniView: View {
    let entries: [CompositionSubstituteEntry]
    var captainMemberKey: String? = nil

    var body: some View {
        if !entries.isEmpty {
            VStack(alignment: .leading, spacing: 6) {
                Text(L10n.text("compositionSubstitutes"))
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(AppPalette.Neutral.textSecondary)

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(entries) { entry in
                            VStack(spacing: 4) {
                                ZStack(alignment: .topTrailing) {
                                    ZStack {
                                        Text(entry.initials)
                                            .font(.system(size: 11, weight: .bold))
                                            .foregroundStyle(AppPalette.Primary.main)
                                            .frame(width: 32, height: 32)
                                            .background {
                                                Circle()
                                                    .fill(AppPalette.Primary.soft)
                                            }
                                    }

                                    if isCaptain(entry) {
                                        CaptainBadgeView(size: 10)
                                            .offset(x: 4, y: -4)
                                    }
                                }

                                Text(entry.fieldDisplayName)
                                    .font(.system(size: 9, weight: .medium))
                                    .foregroundStyle(AppPalette.Neutral.textSecondary)
                                    .lineLimit(1)
                                    .frame(maxWidth: 72)
                            }
                            .accessibilityElement(children: .combine)
                            .accessibilityLabel(
                                isCaptain(entry)
                                    ? "\(entry.displayName), \(L10n.text("compositionCaptain"))"
                                    : entry.displayName
                            )
                        }
                    }
                }
            }
        }
    }

    private func isCaptain(_ entry: CompositionSubstituteEntry) -> Bool {
        guard let captainMemberKey else { return false }
        return CompositionMemberKey.variants(for: captainMemberKey).contains(entry.id)
    }
}

#if DEBUG
#Preview("Compacte") {
    MatchCompositionPreviewView(
        composition: TeamPreviewData.compositions[0],
        members: TeamPreviewData.members,
        isCompositionLocked: true,
        style: .compact
    )
    .padding()
    .teamPreviewEnvironment()
}
#endif
