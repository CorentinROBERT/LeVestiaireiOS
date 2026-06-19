//
//  TeamHeroSection.swift
//  LeVestaire
//

import SwiftUI

struct TeamHeroSection: View {
    @ObservedObject var viewModel: TeamViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Spacer(minLength: 0)
                heroActions
            }

            HStack(alignment: .top, spacing: 14) {
                teamLogo

                VStack(alignment: .leading, spacing: 6) {
                    Text(viewModel.selectedTeam?.name ?? L10n.text("monEquipe"))
                        .font(.title3.weight(.bold))
                        .foregroundStyle(AppPalette.Neutral.textPrimary)
                        .fixedSize(horizontal: false, vertical: true)
                        .frame(maxWidth: .infinity, alignment: .leading)

                    HStack(spacing: 8) {
                        if let role = viewModel.currentUserRole {
                            TeamRoleBadge(role: role)
                        }

                        Text(
                            L10n.format(
                                "membersCount",
                                viewModel.selectedTeam?.resolvedMemberCount ?? 0
                            )
                        )
                        .font(.caption)
                        .foregroundStyle(AppPalette.Neutral.textSecondary)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }

            if viewModel.teams.count > 1 {
                teamPicker
            }

            if let description = viewModel.selectedTeam?.description,
               !description.isEmpty {
                Text(description)
                    .font(.subheadline)
                    .foregroundStyle(AppPalette.Neutral.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            if viewModel.isRefreshingTeam {
                HStack(spacing: 8) {
                    ProgressView()
                        .controlSize(.small)
                    Text(L10n.loading)
                        .font(.caption)
                        .foregroundStyle(AppPalette.Neutral.textSecondary)
                }
            }
        }
        .padding(16)
        .glassEffect(.regular, in: .rect(cornerRadius: 20))
    }

    private var teamPicker: some View {
        Menu {
            ForEach(viewModel.teams) { team in
                Button {
                    viewModel.selectedTeamId = team.id
                    Task { await viewModel.onTeamSelectionChanged() }
                } label: {
                    if team.id == viewModel.selectedTeamId {
                        Label(team.name, systemImage: "checkmark")
                    } else {
                        Text(team.name)
                    }
                }
            }
        } label: {
            HStack(spacing: 8) {
                Text(L10n.text("switchTeam"))
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(AppPalette.Neutral.textSecondary)

                Text(viewModel.selectedTeam?.name ?? L10n.team)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(AppPalette.Primary.main)
                    .lineLimit(1)
                    .truncationMode(.tail)

                Spacer(minLength: 0)

                Image(systemName: "chevron.up.chevron.down")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(AppPalette.Primary.main)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(AppPalette.Primary.soft.opacity(0.35), in: RoundedRectangle(cornerRadius: 12))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var heroActions: some View {
        HStack(spacing: 8) {
            Button {
                viewModel.activeSheet = .createTeam
            } label: {
                Image(systemName: "plus.circle.fill")
                    .font(.title3)
                    .foregroundStyle(AppPalette.Primary.main)
                    .frame(width: 36, height: 36)
                    .background(
                        Circle()
                            .fill(AppPalette.Primary.soft.opacity(0.6))
                    )
            }
            .buttonStyle(.plain)
            .accessibilityLabel(L10n.text("creerUneEquipe"))

            Button {
                viewModel.activeSheet = .settings
            } label: {
                Image(systemName: "gearshape.fill")
                    .font(.body.weight(.semibold))
                    .foregroundStyle(AppPalette.Primary.main)
                    .frame(width: 36, height: 36)
                    .background(
                        Circle()
                            .fill(AppPalette.Primary.soft.opacity(0.6))
                    )
            }
            .buttonStyle(.plain)
            .accessibilityLabel(L10n.settings)
        }
    }

    @ViewBuilder
    private var teamLogo: some View {
        if let logoUrl = RemoteMediaURL.resolve(viewModel.selectedTeam?.logoUrl),
           let url = URL(string: logoUrl) {
            CachedRemoteImage(url: url) { image in
                image
                    .resizable()
                    .scaledToFill()
                    .frame(width: 72, height: 72)
                    .clipShape(RoundedRectangle(cornerRadius: 18))
            } placeholder: {
                teamLogoPlaceholder
            }
        } else {
            teamLogoPlaceholder
        }
    }

    private var teamLogoPlaceholder: some View {
        RoundedRectangle(cornerRadius: 18)
            .fill(AppPalette.Primary.soft)
            .frame(width: 72, height: 72)
            .overlay {
                Image(systemName: "person.3.fill")
                    .font(.title2)
                    .foregroundStyle(AppPalette.Primary.main)
            }
    }
}
