//
//  MatchPresentMembersSection.swift
//  LeVestaire
//

import SwiftUI

struct MatchPresentMembersSection: View {
    @ObservedObject var availabilityViewModel: MatchDetailAvailabilityViewModel

    var body: some View {
        UCard(title: L10n.text("presentMembersTitle"), icon: "person.3.fill") {
            VStack(alignment: .leading, spacing: 12) {
                Text(L10n.text("presentMembersHint"))
                    .font(.caption)
                    .foregroundStyle(AppPalette.Neutral.textSecondary)

                if availabilityViewModel.isLoadingPresentMembers,
                   availabilityViewModel.presentMembers.isEmpty {
                    ProgressView()
                        .frame(maxWidth: .infinity)
                } else if availabilityViewModel.presentMembers.isEmpty {
                    Text(L10n.text("noPresentMembersYet"))
                        .font(.caption)
                        .foregroundStyle(AppPalette.Neutral.textSecondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                } else {
                    Text(L10n.presentPlayersCount(availabilityViewModel.presentMembers.count))
                        .font(.caption.weight(.medium))
                        .foregroundStyle(AppPalette.Primary.main)

                    ForEach(availabilityViewModel.presentMembers) { member in
                        presentMemberRow(member)
                    }
                }
            }
        }
    }

    private func presentMemberRow(_ member: MatchPresentMember) -> some View {
        HStack(spacing: 12) {
            TeamMemberAvatar(initials: member.initials, size: 36)

            Text(member.displayName.isEmpty ? "—" : member.displayName)
                .font(.subheadline.weight(.medium))
                .foregroundStyle(AppPalette.Neutral.textPrimary)

            if member.isGuest {
                TeamGuestBadge()
            }

            Spacer(minLength: 0)
        }
        .padding(.vertical, 2)
        .accessibilityElement(children: .combine)
    }
}

#if DEBUG
#Preview {
    let viewModel = MatchDetailViewModel.preview(status: .draft)
    viewModel.availabilityViewModel.presentMembers = [
        MatchPresentMember(id: "user-3", firstName: "Hugo", lastName: "Petit"),
        MatchPresentMember(id: "user-4", firstName: "Léa", lastName: "Moreau")
    ]
    return MatchPresentMembersSection(availabilityViewModel: viewModel.availabilityViewModel)
        .padding()
        .teamPreviewEnvironment()
}
#endif
