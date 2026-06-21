//
//  TeamPodiumView.swift
//  LeVestaire
//

import SwiftUI

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
            .accessibilityElement(children: .contain)
        }
    }

    private func podiumSlot(rank: Int, entry: RankingPlayerEntry, height: CGFloat) -> some View {
        VStack(spacing: 6) {
            Text(podiumMedal(for: rank))
                .font(.title2)
                .accessibilityHidden(true)
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
        .accessibilityElement(children: .combine)
        .accessibilityLabel(podiumAccessibilityLabel(rank: rank, entry: entry))
    }

    private func podiumAccessibilityLabel(rank: Int, entry: RankingPlayerEntry) -> String {
        let name = entry.displayName.isEmpty ? "—" : entry.displayName
        return "\(rank). \(name), \(entry.scoreValue)"
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
