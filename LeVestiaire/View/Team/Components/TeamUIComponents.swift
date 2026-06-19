//
//  TeamUIComponents.swift
//  LeVestaire
//

import SwiftUI

struct TeamMemberAvatar: View {
    let initials: String
    var size: CGFloat = 40

    var body: some View {
        Circle()
            .fill(AppPalette.Primary.soft)
            .frame(width: size, height: size)
            .overlay {
                Text(initials)
                    .font(size > 44 ? .subheadline.weight(.bold) : .caption.weight(.bold))
                    .foregroundStyle(AppPalette.Primary.main)
            }
    }
}

struct TeamSeasonPicker: View {
    let availableSeasons: [String]
    @Binding var selection: String
    let onChange: () -> Void

    var body: some View {
        HStack {
            Text(L10n.season)
                .font(.subheadline.weight(.semibold))
            Spacer()
            Picker(L10n.season, selection: $selection) {
                ForEach(availableSeasons, id: \.self) { season in
                    Text(SeasonFormatter.shortLabel(for: season)).tag(season)
                }
            }
            .labelsHidden()
            .pickerStyle(.menu)
            .onChange(of: selection) { _, _ in onChange() }
        }
    }
}

struct TeamSectionErrorText: View {
    let message: String

    var body: some View {
        Text(message)
            .font(.caption)
            .foregroundStyle(AppPalette.Semantic.error)
            .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct TeamSectionErrorView: View {
    let message: String
    let onRetry: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            TeamSectionErrorText(message: message)
            Button(L10n.retry, action: onRetry)
                .font(.caption.weight(.semibold))
                .foregroundStyle(AppPalette.Primary.main)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct TeamCollapsedStat: View {
    let label: String
    let value: Int

    var body: some View {
        VStack(spacing: 4) {
            Text("\(value)")
                .font(.headline)
                .foregroundStyle(AppPalette.Primary.dark)
            Text(label)
                .font(.caption2)
                .foregroundStyle(AppPalette.Neutral.textSecondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
    }
}

struct TeamStatCell: View {
    let title: String
    let value: Int

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundStyle(AppPalette.Neutral.textSecondary)
            Text("\(value)")
                .font(.title3.weight(.semibold))
                .foregroundStyle(AppPalette.Primary.dark)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .glassEffect(.regular, in: .rect(cornerRadius: 14))
    }
}

struct TeamPlayerStatBadge: View {
    let label: String
    let value: Int

    var body: some View {
        VStack(spacing: 2) {
            Text("\(value)")
                .font(.caption.weight(.bold))
                .foregroundStyle(AppPalette.Primary.dark)
            Text(label)
                .font(.caption2)
                .foregroundStyle(AppPalette.Neutral.textSecondary)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
    }
}

struct TeamInfoChip: View {
    let title: String
    let value: String

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundStyle(AppPalette.Neutral.textSecondary)
            Text(value)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(AppPalette.Neutral.textPrimary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .glassEffect(.regular, in: .rect(cornerRadius: 14))
    }
}

enum TeamInvitationStatusStyle {
    static func color(for status: TeamInvitationStatus) -> Color {
        switch status {
        case .pending:
            return AppPalette.Primary.main
        case .accepted:
            return AppPalette.Semantic.success
        case .declined, .cancelled:
            return AppPalette.Neutral.textSecondary
        case .expired:
            return AppPalette.Semantic.warning
        case .unknown:
            return AppPalette.Neutral.textTertiary
        }
    }
}

enum TeamRoleStyle {
    static func color(for role: TeamRole?) -> Color {
        switch role {
        case .admin:
            return AppPalette.Primary.main
        case .manager:
            return AppPalette.Secondary.coral
        case .player, .none:
            return AppPalette.Neutral.textSecondary
        }
    }

    static func backgroundColor(for role: TeamRole?) -> Color {
        color(for: role).opacity(0.14)
    }
}

struct TeamEmptyState: View {
    let icon: String
    let title: String
    var message: String?
    var actionTitle: String?
    var action: (() -> Void)?

    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 36))
                .foregroundStyle(AppPalette.Primary.light)

            Text(title)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(AppPalette.Neutral.textPrimary)
                .multilineTextAlignment(.center)

            if let message, !message.isEmpty {
                Text(message)
                    .font(.caption)
                    .foregroundStyle(AppPalette.Neutral.textSecondary)
                    .multilineTextAlignment(.center)
            }

            if let actionTitle, let action {
                Button(actionTitle, action: action)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(AppPalette.Primary.main)
                    .padding(.top, 4)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 24)
        .padding(.horizontal, 12)
    }
}

struct TeamLoadingPlaceholder: View {
    var rowCount: Int = 3

    var body: some View {
        VStack(spacing: 12) {
            ForEach(0..<rowCount, id: \.self) { _ in
                RoundedRectangle(cornerRadius: 14)
                    .fill(AppPalette.Primary.soft.opacity(0.45))
                    .frame(height: 56)
            }
        }
        .redacted(reason: .placeholder)
    }
}

struct TeamKPITile: View {
    private static let tileHeight: CGFloat = 84
    private static let valueHeight: CGFloat = 30
    private static let labelHeight: CGFloat = 30
    private static let unavailableValue = "—"

    let value: String
    let label: String
    var accent: Color = AppPalette.Primary.main
    var isUnavailable: Bool = false

    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.title2.weight(.bold))
                .foregroundStyle(isUnavailable ? AppPalette.Neutral.textTertiary : accent)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
                .frame(height: Self.valueHeight)

            Text(label)
                .font(.caption2)
                .foregroundStyle(AppPalette.Neutral.textSecondary)
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .minimumScaleFactor(0.75)
                .frame(maxWidth: .infinity)
                .frame(height: Self.labelHeight, alignment: .center)
                .padding(.horizontal, 4)
        }
        .frame(maxWidth: .infinity)
        .frame(height: Self.tileHeight)
        .glassEffect(.regular, in: .rect(cornerRadius: 16))
    }

    static var unavailablePlaceholder: String { unavailableValue }
}

struct TeamColoredActionTile: View {
    let title: String
    let subtitle: String
    let icon: String
    let tint: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 10) {
                Image(systemName: icon)
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(tint)

                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(AppPalette.Neutral.textPrimary)
                    Text(subtitle)
                        .font(.caption)
                        .foregroundStyle(AppPalette.Neutral.textSecondary)
                        .multilineTextAlignment(.leading)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(14)
            .background(tint.opacity(0.1), in: RoundedRectangle(cornerRadius: 18))
            .overlay {
                RoundedRectangle(cornerRadius: 18)
                    .stroke(tint.opacity(0.22), lineWidth: 1)
            }
        }
        .buttonStyle(.plain)
    }
}

struct TeamRoleBadge: View {
    let role: TeamRole

    var body: some View {
        Text(role.localizedLabel)
            .font(.caption2.weight(.semibold))
            .foregroundStyle(TeamRoleStyle.color(for: role))
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(TeamRoleStyle.backgroundColor(for: role), in: Capsule())
    }
}

struct TeamJerseyBadge: View {
    let number: Int

    var body: some View {
        Text("\(number)")
            .font(.caption.weight(.bold))
            .foregroundStyle(AppPalette.Primary.dark)
            .frame(width: 28, height: 28)
            .background(AppPalette.Primary.soft, in: Circle())
    }
}

struct TeamGuestBadge: View {
    var body: some View {
        Text(L10n.text("guestLabel"))
            .font(.caption2.weight(.semibold))
            .foregroundStyle(AppPalette.Secondary.mintDark)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(AppPalette.Secondary.mint.opacity(0.14), in: Capsule())
    }
}

struct TeamPodiumView: View {
    let entries: [RankingPlayerEntry]

    var body: some View {
        if entries.count >= 2 {
            HStack(alignment: .bottom, spacing: 10) {
                if entries.count > 1 {
                    podiumSlot(rank: 2, entry: entries[1], height: 72)
                }
                podiumSlot(rank: 1, entry: entries[0], height: 92)
                if entries.count > 2 {
                    podiumSlot(rank: 3, entry: entries[2], height: 60)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.bottom, 8)
        }
    }

    private func podiumSlot(rank: Int, entry: RankingPlayerEntry, height: CGFloat) -> some View {
        VStack(spacing: 6) {
            Text(podiumMedal(for: rank))
                .font(.title2)
            Text(entry.displayName.isEmpty ? "—" : entry.displayName)
                .font(.caption.weight(.semibold))
                .foregroundStyle(AppPalette.Neutral.textPrimary)
                .lineLimit(2)
                .multilineTextAlignment(.center)

            if entry.isGuest {
                TeamGuestBadge()
            }

            Text("\(entry.scoreValue)")
                .font(.subheadline.weight(.bold))
                .foregroundStyle(AppPalette.Primary.dark)
            RoundedRectangle(cornerRadius: 10)
                .fill(podiumColor(for: rank).opacity(0.22))
                .frame(height: height)
                .overlay(alignment: .top) {
                    Text("\(rank)")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(podiumColor(for: rank))
                        .padding(.top, 8)
                }
        }
        .frame(maxWidth: .infinity)
    }

    private func podiumMedal(for rank: Int) -> String {
        switch rank {
        case 1: return "🥇"
        case 2: return "🥈"
        default: return "🥉"
        }
    }

    private func podiumColor(for rank: Int) -> Color {
        switch rank {
        case 1: return AppPalette.Semantic.warning
        case 2: return AppPalette.Neutral.textSecondary
        default: return AppPalette.Secondary.coral
        }
    }
}
