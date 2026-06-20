//
//  MatchEventsTimelineView.swift
//  LeVestaire
//

import SwiftUI

struct MatchEventsTimelineView: View {
    let events: [MatchEvent]
    let canManageEvents: Bool
    let isSubmitting: Bool
    let onDelete: (String) -> Void

    private var grouped: MatchEventsGrouped {
        events.groupedForTimeline
    }

    var body: some View {
        if grouped.hasBoundaries {
            framedTimeline
        } else {
            plainList(grouped.middleEvents + grouped.startEvents + grouped.endEvents)
        }
    }

    private var framedTimeline: some View {
        VStack(spacing: 0) {
            ForEach(grouped.startEvents) { event in
                boundaryRow(event, style: .start)
            }

            if !grouped.middleEvents.isEmpty {
                plainList(grouped.middleEvents)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 10)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(AppPalette.Neutral.surface.opacity(0.55))
            } else if grouped.hasBoundaries {
                Text(L10n.text("eventsWillAppearHere"))
                    .font(.caption)
                    .foregroundStyle(AppPalette.Neutral.textSecondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 16)
                    .background(AppPalette.Neutral.surface.opacity(0.55))
            }

            ForEach(grouped.endEvents) { event in
                boundaryRow(event, style: .end)
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(AppPalette.Primary.main.opacity(0.22), lineWidth: 1.5)
        }
    }

    @ViewBuilder
    private func plainList(_ events: [MatchEvent]) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            ForEach(events) { event in
                eventRow(event)
            }
        }
    }

    private enum BoundaryStyle {
        case start
        case end
    }

    private func boundaryRow(_ event: MatchEvent, style: BoundaryStyle) -> some View {
        HStack(spacing: 8) {
            Image(systemName: style == .start ? "play.circle.fill" : "flag.checkered")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(boundaryTint(for: style))

            Text(event.displayLabel)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(AppPalette.Neutral.textPrimary)

            Spacer(minLength: 0)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(boundaryBackground(for: style))
    }

    private func boundaryBackground(for style: BoundaryStyle) -> Color {
        switch style {
        case .start:
            return AppPalette.Semantic.success.opacity(0.14)
        case .end:
            return AppPalette.Neutral.textSecondary.opacity(0.12)
        }
    }

    private func boundaryTint(for style: BoundaryStyle) -> Color {
        switch style {
        case .start:
            return AppPalette.Semantic.success
        case .end:
            return AppPalette.Neutral.textSecondary
        }
    }

    private func eventRow(_ event: MatchEvent) -> some View {
        HStack(alignment: .center, spacing: 8) {
            Image(systemName: eventIcon(for: event.type))
                .font(.caption.weight(.semibold))
                .foregroundStyle(eventTint(for: event.type))
                .frame(width: 24, height: 24)
                .background(
                    RoundedRectangle(cornerRadius: 6)
                        .fill(eventTint(for: event.type).opacity(0.12))
                )

            VStack(alignment: .leading, spacing: 2) {
                Text(event.displayLabel)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(AppPalette.Neutral.textPrimary)

                if let comment = event.comment, !comment.isEmpty {
                    Text(comment)
                        .font(.caption)
                        .foregroundStyle(AppPalette.Neutral.textSecondary)
                }
            }

            Spacer(minLength: 8)

            if canManageEvents, event.isDeletable {
                Button(role: .destructive) {
                    onDelete(event.id)
                } label: {
                    Image(systemName: "trash")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(AppPalette.Semantic.error)
                        .frame(width: 24, height: 24)
                        .background(
                            RoundedRectangle(cornerRadius: 6)
                                .fill(AppPalette.Semantic.error.opacity(0.12))
                        )
                }
                .buttonStyle(.plain)
                .disabled(isSubmitting)
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(AppPalette.Neutral.surface)
        )
    }

    private func eventIcon(for type: MatchEventType) -> String {
        switch type {
        case .goal, .opponentGoal:
            return "soccerball"
        case .ownGoal, .opponentOwnGoal:
            return "arrow.triangle.2.circlepath"
        case .assist:
            return "hand.point.right.fill"
        case .yellowCard:
            return "rectangle.fill"
        case .redCard:
            return "rectangle.fill"
        case .substitution:
            return "arrow.left.arrow.right"
        case .matchStart:
            return "play.circle.fill"
        case .matchEnd:
            return "flag.checkered"
        case .shotOnTarget:
            return "scope"
        case .save:
            return "hand.raised.fill"
        case .injury:
            return "cross.case.fill"
        case .manOfTheMatch:
            return "star.fill"
        case .shlag, .other:
            return "ellipsis.circle.fill"
        }
    }

    private func eventTint(for type: MatchEventType) -> Color {
        switch type {
        case .goal, .assist, .manOfTheMatch:
            return AppPalette.Semantic.success
        case .ownGoal, .opponentOwnGoal:
            return AppPalette.Semantic.warning
        case .opponentGoal:
            return AppPalette.Secondary.coral
        case .yellowCard:
            return AppPalette.Semantic.warning
        case .redCard, .injury:
            return AppPalette.Semantic.error
        case .substitution, .shotOnTarget, .save:
            return AppPalette.Primary.main
        case .matchStart:
            return AppPalette.Semantic.success
        case .matchEnd:
            return AppPalette.Neutral.textSecondary
        case .shlag, .other:
            return AppPalette.Neutral.textTertiary
        }
    }
}
