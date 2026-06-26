//
//  CompositionCaptainSection.swift
//  LeVestaire
//

import SwiftUI

struct CompositionCaptainSection: View {
    let members: [TeamMember]
    let tab: CompositionTabDraft
    @Binding var captainMemberKey: String?
    let canEdit: Bool
    let onPersistCaptain: ((String?) async -> Bool)?

    @State private var showsCaptainPicker = false
    @State private var isUpdatingCaptain = false

    private var lineupMembers: [TeamMember] {
        tab.lineupMembers(from: members)
    }

    private var captain: TeamMember? {
        guard let captainMemberKey else { return nil }
        return members.first { $0.matchesCompositionMemberKey(captainMemberKey) }
    }

    private var hasLineup: Bool {
        !lineupMembers.isEmpty
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(L10n.text("compositionCaptain"))
                .font(.subheadline.weight(.semibold))

            if !hasLineup {
                Text(L10n.text("compositionCaptainRequiresLineup"))
                    .font(.caption)
                    .foregroundStyle(AppPalette.Neutral.textSecondary)
            } else if let captain {
                captainRow(for: captain)
            } else {
                selectCaptainButton
            }
        }
        .sheet(isPresented: $showsCaptainPicker) {
            CaptainPickerSheet(
                members: lineupMembers,
                selectedCaptain: captain,
                onSelect: { member in
                    Task { await applyCaptain(member?.compositionMemberKey) }
                }
            )
        }
    }

    private var selectCaptainButton: some View {
        Button {
            showsCaptainPicker = true
        } label: {
            HStack(spacing: 12) {
                Image(systemName: "c.circle")
                    .font(.title3)
                    .foregroundStyle(AppPalette.Primary.main)
                    .frame(width: 36)

                Text(
                    canEdit
                        ? L10n.text("selectCompositionCaptain")
                        : L10n.text("noCompositionCaptain")
                )
                .foregroundStyle(AppPalette.Neutral.textPrimary)

                Spacer(minLength: 0)

                if canEdit {
                    Image(systemName: "chevron.right")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(AppPalette.Neutral.textTertiary)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .contentShape(Rectangle())
            .padding(12)
            .glassEffect(.regular, in: .rect(cornerRadius: 16))
        }
        .buttonStyle(.plain)
        .disabled(!canEdit || isUpdatingCaptain)
    }

    private func captainRow(for captain: TeamMember) -> some View {
        Button {
            guard canEdit else { return }
            showsCaptainPicker = true
        } label: {
            HStack(spacing: 12) {
                ZStack(alignment: .topTrailing) {
                    Circle()
                        .fill(AppPalette.Primary.soft)
                        .frame(width: 36, height: 36)
                        .overlay {
                            Text(captain.initials)
                                .font(.caption.weight(.bold))
                                .foregroundStyle(AppPalette.Primary.main)
                        }

                    CaptainBadgeView(size: 14)
                        .offset(x: 4, y: -4)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(captain.displayName)
                        .foregroundStyle(AppPalette.Neutral.textPrimary)
                    Text(L10n.text("compositionCaptain"))
                        .font(.caption)
                        .foregroundStyle(AppPalette.Neutral.textSecondary)
                }

                Spacer(minLength: 0)

                if isUpdatingCaptain {
                    ProgressView()
                } else if canEdit {
                    Image(systemName: "chevron.right")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(AppPalette.Neutral.textTertiary)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .contentShape(Rectangle())
            .padding(12)
            .glassEffect(.regular, in: .rect(cornerRadius: 16))
        }
        .buttonStyle(.plain)
        .disabled(!canEdit || isUpdatingCaptain)
    }

    @MainActor
    private func applyCaptain(_ memberKey: String?) async {
        guard canEdit else { return }

        isUpdatingCaptain = true
        defer { isUpdatingCaptain = false }

        if let onPersistCaptain {
            if await onPersistCaptain(memberKey) {
                captainMemberKey = memberKey
            }
        } else {
            captainMemberKey = memberKey
        }
    }
}

private struct CaptainPickerSheet: View {
    @Environment(\.dismiss) private var dismiss

    let members: [TeamMember]
    let selectedCaptain: TeamMember?
    let onSelect: (TeamMember?) -> Void

    var body: some View {
        NavigationStack {
            List {
                if selectedCaptain != nil {
                    Section {
                        Button(role: .destructive) {
                            onSelect(nil)
                            dismiss()
                        } label: {
                            HStack(spacing: 12) {
                                Image(systemName: "c.circle")
                                    .frame(width: 36)
                                Text(L10n.text("removeCaptain"))
                            }
                        }
                    }
                }

                Section {
                    if members.isEmpty {
                        Text(L10n.text("compositionCaptainRequiresLineup"))
                            .foregroundStyle(AppPalette.Neutral.textSecondary)
                    } else {
                        ForEach(members) { member in
                            Button {
                                onSelect(member)
                                dismiss()
                            } label: {
                                HStack(spacing: 12) {
                                    Circle()
                                        .fill(AppPalette.Primary.soft)
                                        .frame(width: 36, height: 36)
                                        .overlay {
                                            Text(member.initials)
                                                .font(.caption.weight(.bold))
                                                .foregroundStyle(AppPalette.Primary.main)
                                        }

                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(member.displayName)
                                            .foregroundStyle(AppPalette.Neutral.textPrimary)
                                        if let role = member.role {
                                            Text(role.localizedLabel)
                                                .font(.caption)
                                                .foregroundStyle(AppPalette.Neutral.textSecondary)
                                        }
                                    }

                                    Spacer()

                                    if let selectedCaptain,
                                       member.matchesCompositionMemberKey(selectedCaptain.compositionMemberKey) {
                                        Image(systemName: "checkmark")
                                            .foregroundStyle(AppPalette.Primary.main)
                                    }
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle(L10n.text("selectCompositionCaptain"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button(L10n.cancel) { dismiss() }
                }
            }
        }
    }
}

struct CaptainBadgeView: View {
    var size: CGFloat = 14

    var body: some View {
        Text("C")
            .font(.system(size: size * 0.62, weight: .heavy))
            .foregroundStyle(.black.opacity(0.85))
            .frame(width: size, height: size)
            .background {
                Circle()
                    .fill(Color(red: 1.0, green: 0.84, blue: 0.0))
            }
            .overlay {
                Circle()
                    .strokeBorder(.black.opacity(0.18), lineWidth: 0.5)
            }
    }
}

#if DEBUG
#Preview {
    CompositionCaptainSection(
        members: TeamPreviewData.members,
        tab: CompositionTabDraft.from(composition: TeamPreviewData.compositions[0]).first!,
        captainMemberKey: .constant("user-3"),
        canEdit: true,
        onPersistCaptain: nil
    )
    .padding()
    .teamPreviewEnvironment()
}
#endif
