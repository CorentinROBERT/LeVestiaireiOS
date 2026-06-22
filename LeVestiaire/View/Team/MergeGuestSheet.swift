//
//  MergeGuestSheet.swift
//  LeVestaire
//

import SwiftUI

struct MergeGuestSheet: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var rosterViewModel: TeamRosterViewModel

    let guest: TeamMember

    init(viewModel: TeamViewModel, guest: TeamMember) {
        self.rosterViewModel = viewModel.rosterViewModel
        self.guest = guest
    }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    Text(L10n.text("mergeGuestDescription"))
                        .font(.subheadline)
                        .foregroundStyle(AppPalette.Neutral.textSecondary)
                        .listRowBackground(Color.clear)
                        .listRowInsets(EdgeInsets(top: 8, leading: 0, bottom: 8, trailing: 0))
                }

                Section {
                    HStack(spacing: 12) {
                        TeamMemberAvatar(initials: guest.initials)
                        VStack(alignment: .leading, spacing: 4) {
                            Text(guest.displayName)
                                .font(.subheadline.weight(.semibold))
                            TeamGuestBadge()
                        }
                    }
                } header: {
                    Text(L10n.text("guestLabel"))
                }

                Section {
                    if rosterViewModel.mergeableTeamMembers.isEmpty {
                        Text(L10n.text("emptyPlayersMessage"))
                            .foregroundStyle(AppPalette.Neutral.textSecondary)
                    } else {
                        ForEach(rosterViewModel.mergeableTeamMembers) { member in
                            Button {
                                Task {
                                    if await rosterViewModel.mergeGuest(with: member) {
                                        dismiss()
                                    }
                                }
                            } label: {
                                HStack(spacing: 12) {
                                    if let jerseyNumber = member.jerseyNumber {
                                        TeamJerseyBadge(number: jerseyNumber)
                                    } else {
                                        TeamMemberAvatar(initials: member.initials)
                                    }

                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(member.displayName)
                                            .foregroundStyle(AppPalette.Neutral.textPrimary)
                                        if let role = member.role {
                                            Text(role.localizedLabel)
                                                .font(.caption)
                                                .foregroundStyle(AppPalette.Neutral.textSecondary)
                                        }
                                    }

                                    Spacer()

                                    if rosterViewModel.isSubmitting {
                                        ProgressView()
                                    }
                                }
                            }
                            .disabled(rosterViewModel.isSubmitting)
                        }
                    }
                } header: {
                    Text(L10n.text("selectAssociatedPlayer"))
                }
            }
            .listStyle(.insetGrouped)
            .scrollContentBackground(.hidden)
            .background(AuthScreenBackground())
            .navigationTitle(L10n.text("mergeGuestTitle"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button(L10n.cancel) {
                        rosterViewModel.guestPendingMerge = nil
                        dismiss()
                    }
                }
            }
        }
    }
}

#if DEBUG
#Preview {
    MergeGuestSheet(
        viewModel: .preview(),
        guest: TeamMember(
            id: "guest-preview",
            firstName: "Invité",
            lastName: "Test",
            isGuest: true
        )
    )
    .teamPreviewEnvironment()
}
#endif
