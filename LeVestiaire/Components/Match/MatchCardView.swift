//
//  MatchCardView.swift
//  LeVestaire
//
//  Created by Corentin Robert on 17/06/2026.
//

import SwiftUI

/// Carte match unifiée pour le listing : infos + disponibilité dans le même conteneur visuel.
struct MatchListingCard: View {
    let match: MatchItem
    var isSubmittingAvailability: Bool = false
    var onAvailabilitySelect: ((MatchAvailabilityStatus) -> Void)?

    private var showsAvailabilityActions: Bool {
        match.canRespondFromListing && onAvailabilitySelect != nil
    }

    var body: some View {
        VStack(spacing: 0) {
            NavigationLink(value: match.id) {
                MatchCardContent(
                    match: match,
                    showsAvailabilityFooter: !showsAvailabilityActions
                )
                .padding(16)
                .contentShape(Rectangle())
            }
            .buttonStyle(.fullTap)

            if showsAvailabilityActions, let onAvailabilitySelect {
                MatchAvailabilityQuickRespondBar(
                    matchContext: availabilityContextLabel,
                    selectedStatus: match.myAvailabilityStatus,
                    isSubmitting: isSubmittingAvailability,
                    layout: .embedded,
                    onSelect: onAvailabilitySelect
                )
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .glassEffect(.regular, in: .rect(cornerRadius: 16))
        .overlay {
            RoundedRectangle(cornerRadius: 16)
                .stroke(match.status.color.opacity(0.25), lineWidth: 1.5)
        }
    }

    private var availabilityContextLabel: String {
        if let time = match.formattedTime, !time.isEmpty {
            return "\(match.formattedDate) · \(time)"
        }
        return match.formattedDate
    }
}

struct MatchCardView: View {
    let match: MatchItem

    var body: some View {
        MatchCardContent(match: match, showsAvailabilityFooter: true)
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .glassEffect(.regular, in: .rect(cornerRadius: 16))
            .overlay {
                RoundedRectangle(cornerRadius: 16)
                    .stroke(match.status.color.opacity(0.25), lineWidth: 1.5)
            }
    }
}

private struct MatchCardContent: View {
    let match: MatchItem
    let showsAvailabilityFooter: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            headerRow
            if let scoreText = match.scoreText, match.showsScore {
                scoreRow(scoreText)
            }
            infoRow
            if showsAvailabilityFooter {
                availabilityFooter
            }
        }
    }

    private var headerRow: some View {
        HStack(alignment: .top, spacing: 8) {
            if let homeTeamName = match.homeTeamName, !homeTeamName.isEmpty {
                Text(homeTeamName)
                    .font(.caption.weight(.medium))
                    .foregroundStyle(AppPalette.Primary.main)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(
                        Capsule()
                            .fill(AppPalette.Primary.main.opacity(0.12))
                    )
            }

            Text(match.title)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(AppPalette.Neutral.textPrimary)
                .lineLimit(2)
                .frame(maxWidth: .infinity, alignment: .leading)

            Text(match.resolvedStatusLabel)
                .font(.caption.weight(.semibold))
                .foregroundStyle(AppPalette.Primary.onMain)
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
                .background(
                    Capsule()
                        .fill(match.status.color)
                )
        }
    }

    @ViewBuilder
    private var availabilityFooter: some View {
        if match.canRespondFromListing, let label = match.myAvailabilityLabel {
            Label(label, systemImage: "hand.raised.fill")
                .font(.caption)
                .foregroundStyle(AppPalette.Primary.main)
        } else if match.showsPrepareOnListing, let summary = match.availabilitySummaryLabel {
            Label(summary, systemImage: "person.2.fill")
                .font(.caption)
                .foregroundStyle(AppPalette.Neutral.textSecondary)
        } else if match.status.isPreparationStatus, let label = match.myAvailabilityLabel {
            Label(label, systemImage: "hand.raised.fill")
                .font(.caption)
                .foregroundStyle(AppPalette.Neutral.textSecondary)
        }
    }

    private func scoreRow(_ scoreText: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: "house.fill")
                .font(.caption)
                .foregroundStyle(AppPalette.Primary.main)

            Text(scoreText)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(AppPalette.Neutral.textPrimary)

            Image(systemName: "airplane.departure")
                .font(.caption)
                .foregroundStyle(AppPalette.Primary.main)
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(AppPalette.Primary.main.opacity(0.08))
        )
    }

    private var infoRow: some View {
        HStack(spacing: 12) {
            infoTile(
                icon: "calendar",
                title: match.formattedDate,
                subtitle: match.formattedTime,
                tint: AppPalette.Primary.main
            )

            infoTile(
                icon: "sportscourt.fill",
                title: opponentLabel,
                subtitle: match.location,
                tint: AppPalette.Secondary.coral
            )
        }
    }

    private var opponentLabel: String {
        if let opponent = match.opponentTeam, !opponent.isEmpty {
            return "\(L10n.vs) \(opponent)"
        }
        return L10n.opponentToBeDefined
    }

    private func infoTile(
        icon: String,
        title: String,
        subtitle: String?,
        tint: Color
    ) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundStyle(tint)
                .frame(width: 24, height: 24)
                .background(
                    RoundedRectangle(cornerRadius: 6)
                        .fill(tint.opacity(0.15))
                )

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.caption)
                    .foregroundStyle(AppPalette.Neutral.textPrimary)
                    .lineLimit(1)

                if let subtitle, !subtitle.isEmpty {
                    Text(subtitle)
                        .font(.caption2)
                        .foregroundStyle(AppPalette.Neutral.textSecondary)
                        .lineLimit(1)
                }
            }

            Spacer(minLength: 0)
        }
        .padding(8)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(tint.opacity(0.08))
        )
    }
}

#if DEBUG
#Preview("Upcoming") {
    ZStack {
        AuthScreenBackground()

        MatchCardView(
            match: MatchItem(
                id: "1",
                title: "Match amical",
                status: .upcoming,
                opponentTeam: "FC Rivaux",
                location: "Stade municipal",
                homeTeamName: "Mon équipe",
                date: Date(),
                startTime: "20:00"
            )
        )
        .padding()
    }
}

#Preview("Listing avec disponibilité") {
    ZStack {
        AuthScreenBackground()

        MatchListingCard(
            match: MatchItem(
                id: "2",
                title: "vs Teuteu",
                status: .draft,
                myAvailabilityStatus: .available,
                capabilities: MatchCapabilities(
                    canRespond: true,
                    canManageAvailability: false,
                    canManageComposition: false,
                    canPublish: false,
                    canStartMatch: false,
                    canManageEvents: false,
                    canUpdateScore: false,
                    canFinishMatch: false
                ),
                opponentTeam: "Teuteu",
                location: "Stade municipal",
                homeTeamName: "PFC",
                date: Date(),
                startTime: "20:00"
            ),
            isSubmittingAvailability: false,
            onAvailabilitySelect: { _ in }
        )
        .padding()
    }
}
#endif
