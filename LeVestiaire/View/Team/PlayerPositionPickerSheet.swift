//
//  PlayerPositionPickerSheet.swift
//  LeVestaire
//

import SwiftUI

struct PlayerPositionPickerSheet: View {
    @Environment(\.dismiss) private var dismiss

    let members: [TeamMember]
    let assignedMemberIds: Set<String>
    let slotOccupant: TeamMember?
    let onSelect: (TeamMember) -> Void
    let onClear: (() -> Void)?

    @AppStorage(CompositionPickerPreferences.showsAssignedPlayersKey)
    private var showsAssignedPlayers = true

    private var filteredMembers: [TeamMember] {
        members.filter { member in
            if showsAssignedPlayers {
                return true
            }
            return !assignedMemberIds.contains(where: { member.matchesCompositionMemberKey($0) })
        }
    }

    var body: some View {
        NavigationStack {
            List {
                if let slotOccupant, onClear != nil {
                    Section {
                        Button(role: .destructive) {
                            onClear?()
                            dismiss()
                        } label: {
                            HStack(spacing: 12) {
                                Image(systemName: "person.fill.xmark")
                                    .frame(width: 36)

                                VStack(alignment: .leading, spacing: 2) {
                                    Text(L10n.removePlayerFromPosition)
                                    Text(slotOccupant.displayName)
                                        .font(.caption)
                                        .foregroundStyle(AppPalette.Neutral.textSecondary)
                                }
                            }
                        }
                    }
                }

                Toggle(L10n.showAssignedPlayers, isOn: $showsAssignedPlayers)

                if filteredMembers.isEmpty {
                    Text(L10n.text("playerSelectionNoFriends"))
                        .foregroundStyle(AppPalette.Neutral.textSecondary)
                } else {
                    ForEach(filteredMembers) { member in
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

                                if assignedMemberIds.contains(where: { member.matchesCompositionMemberKey($0) }) {
                                    Text(L10n.text("compositionStarters"))
                                        .font(.caption2)
                                        .foregroundStyle(AppPalette.Neutral.textTertiary)
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle(L10n.text("players"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(L10n.close) { dismiss() }
                }
            }
        }
        .presentationDetents([.medium, .large])
    }
}

private enum CompositionPickerPreferences {
    static let showsAssignedPlayersKey = "compositionPickerShowsAssignedPlayers"
}

#if DEBUG
#Preview {
    PlayerPositionPickerSheet(
        members: TeamPreviewData.members,
        assignedMemberIds: Set(TeamPreviewData.fieldAssignments.values),
        slotOccupant: TeamPreviewData.members.first,
        onSelect: { _ in },
        onClear: {}
    )
    .teamPreviewEnvironment()
}
#endif
