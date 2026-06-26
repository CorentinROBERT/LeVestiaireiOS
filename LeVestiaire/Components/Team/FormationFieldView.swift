//
//  FormationFieldView.swift
//  LeVestaire
//

import SwiftUI

struct FormationFieldView: View {
    let formationKey: String
    let members: [TeamMember]
    let assignments: [String: String]
    let onPositionTapped: (String) -> Void
    var interactive: Bool = true
    var compact: Bool = false
    var captainMemberKey: String? = nil

    private var markerScale: CGFloat {
        compact ? 0.8 : 1.5
    }

    private var circleSize: CGFloat { 34 * markerScale }
    private var stackSpacing: CGFloat { compact ? 3 : 4 * markerScale }
    private var resolvedInitialsFontSize: CGFloat { compact ? 12 : 16.5 }
    private var nameFontSize: CGFloat { compact ? 9.5 : 9 * markerScale }
    private var nameHorizontalPadding: CGFloat { compact ? 5 : 6 * markerScale }
    private var nameVerticalPadding: CGFloat { compact ? 2 : 2 * markerScale }
    private var nameMaxWidth: CGFloat { compact ? 72 : 80 * markerScale }
    private var nameBorderWidth: CGFloat { 0.5 * markerScale }
    private var nameShadowRadius: CGFloat { compact ? 1.5 : 2 * markerScale }
    private var fieldCornerRadius: CGFloat { compact ? 12 : 16 }
    private var fieldAspectRatio: CGFloat { 0.68 }
    static let compactFieldHeight: CGFloat = 272
    private var fieldInset: CGFloat { compact ? 6 : 8 }
    /// Le terrain garde un fond vert + cercles blancs : la couleur du label ne doit pas suivre le dark mode app.
    private static let emptySlotLabelColor = Color(red: 0.10, green: 0.22, blue: 0.48)

    private var formation: FormationTemplate {
        FormationCatalog.template(for: formationKey) ?? FormationCatalog.all[0]
    }

    var body: some View {
        Group {
            if compact {
                fieldContent
                    .frame(height: Self.compactFieldHeight)
            } else {
                fieldContent
                    .aspectRatio(fieldAspectRatio, contentMode: .fit)
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: fieldCornerRadius))
    }

    private var fieldContent: some View {
        GeometryReader { geometry in
            ZStack {
                RoundedRectangle(cornerRadius: fieldCornerRadius)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color(red: 0.16, green: 0.55, blue: 0.22),
                                Color(red: 0.10, green: 0.42, blue: 0.16)
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )

                GrassStripePattern()
                    .clipShape(RoundedRectangle(cornerRadius: fieldCornerRadius))

                FieldLinesView()
                    .padding(fieldInset)

                ForEach(formation.positions) { position in
                    let point = position.normalizedPoint
                    positionButton(
                        position: position,
                        member: member(for: position.id)
                    )
                    .position(
                        x: point.x * geometry.size.width,
                        y: point.y * geometry.size.height
                    )
                }
            }
        }
    }

    @ViewBuilder
    private func positionButton(position: FormationPosition, member: TeamMember?) -> some View {
        let marker = VStack(spacing: stackSpacing) {
            ZStack(alignment: .topTrailing) {
                ZStack {
                    Circle()
                        .fill(member == nil ? Color.white.opacity(0.92) : AppPalette.Primary.main)
                        .frame(width: circleSize, height: circleSize)
                    Text(member?.initials ?? position.localizedMarkerLabel)
                        .font(.system(size: resolvedInitialsFontSize, weight: .bold))
                        .foregroundStyle(member == nil ? Self.emptySlotLabelColor : .white)
                        .lineLimit(1)
                        .minimumScaleFactor(0.65)
                }

                if isCaptain(member) {
                    CaptainBadgeView(size: compact ? 11 : 13)
                        .offset(x: compact ? 5 : 6, y: compact ? -5 : -6)
                }
            }

            if let member {
                Text(compact ? member.fieldDisplayName : member.displayName)
                    .font(.system(size: nameFontSize, weight: .semibold))
                    .foregroundStyle(.white)
                    .lineLimit(1)
                    .minimumScaleFactor(0.65)
                    .padding(.horizontal, nameHorizontalPadding)
                    .padding(.vertical, nameVerticalPadding)
                    .background {
                        Capsule()
                            .fill(.black.opacity(0.62))
                            .overlay {
                                Capsule()
                                    .strokeBorder(
                                        .white.opacity(0.18),
                                        lineWidth: nameBorderWidth
                                    )
                            }
                    }
                    .shadow(
                        color: .black.opacity(0.35),
                        radius: nameShadowRadius,
                        y: 1
                    )
                    .frame(maxWidth: nameMaxWidth)
            }
        }

        if interactive {
            Button {
                onPositionTapped(position.id)
            } label: {
                marker
            }
            .buttonStyle(.fullTap)
            .accessibilityLabel(positionAccessibilityLabel(position: position, member: member))
            .accessibilityHint(L10n.text("select"))
        } else {
            marker
        }
    }

    private func member(for positionId: String) -> TeamMember? {
        guard let memberId = assignments[positionId] else { return nil }
        return members.first { $0.matchesCompositionMemberKey(memberId) }
    }

    private func isCaptain(_ member: TeamMember?) -> Bool {
        guard let member, let captainMemberKey else { return false }
        return member.matchesCompositionMemberKey(captainMemberKey)
    }

    private func positionAccessibilityLabel(position: FormationPosition, member: TeamMember?) -> String {
        if let member {
            let captainSuffix = isCaptain(member)
                ? ", \(L10n.text("compositionCaptain"))"
                : ""
            return "\(position.localizedMarkerLabel), \(member.displayName)\(captainSuffix)"
        }
        return position.localizedMarkerLabel
    }
}

private struct GrassStripePattern: View {
    var body: some View {
        Canvas { context, size in
            let stripeCount = 10
            let stripeWidth = size.width / CGFloat(stripeCount)
            for index in 0..<stripeCount where index.isMultiple(of: 2) {
                var stripe = Path()
                stripe.addRect(
                    CGRect(
                        x: CGFloat(index) * stripeWidth,
                        y: 0,
                        width: stripeWidth,
                        height: size.height
                    )
                )
                context.fill(stripe, with: .color(.white.opacity(0.045)))
            }
        }
    }
}

struct SubstitutesBenchView: View {
    let members: [TeamMember]
    let substituteMemberIds: [String?]
    let onBenchSlotTapped: (Int) -> Void
    var interactive: Bool = true
    var captainMemberKey: String? = nil

    var body: some View {
        let visibleIndices = visibleSlotIndices
        if visibleIndices.isEmpty {
            EmptyView()
        } else {
            VStack(alignment: .leading, spacing: 8) {
                Text(L10n.text("compositionSubstitutes"))
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(AppPalette.Neutral.textPrimary)

                HStack(spacing: 10) {
                    ForEach(visibleIndices, id: \.self) { index in
                        benchSlot(index: index)
                    }
                }
            }
        }
    }

    private var visibleSlotIndices: [Int] {
        if interactive {
            return Array(substituteMemberIds.indices)
        }
        return substituteMemberIds.indices.filter { substituteMemberIds[$0] != nil }
    }

    @ViewBuilder
    private func benchSlot(index: Int) -> some View {
        let memberId = substituteMemberIds[index]
        let member = members.first { member in
            guard let memberId else { return false }
            return member.matchesCompositionMemberKey(memberId)
        }

        let slotContent = VStack(spacing: 6) {
            ZStack(alignment: .topTrailing) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(AppPalette.Neutral.surface.opacity(0.8))
                        .frame(height: 56)
                    if let member {
                        Text(member.initials)
                            .font(.subheadline.weight(.bold))
                            .foregroundStyle(AppPalette.Primary.main)
                    } else if interactive {
                        Image(systemName: "plus")
                            .foregroundStyle(AppPalette.Neutral.textSecondary)
                    } else {
                        Text("—")
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(AppPalette.Neutral.textTertiary)
                    }
                }

                if let member, isCaptain(member) {
                    CaptainBadgeView(size: 13)
                        .offset(x: 5, y: -5)
                }
            }

            Text(
                member?.displayName
                    ?? (interactive ? L10n.text("select") : "—")
            )
            .font(.caption2)
            .foregroundStyle(AppPalette.Neutral.textSecondary)
            .lineLimit(1)
        }
        .frame(maxWidth: .infinity)

        if interactive {
            Button {
                onBenchSlotTapped(index)
            } label: {
                slotContent
            }
            .buttonStyle(.fullTap)
        } else if member != nil {
            slotContent
        }
    }

    private func isCaptain(_ member: TeamMember) -> Bool {
        guard let captainMemberKey else { return false }
        return member.matchesCompositionMemberKey(captainMemberKey)
    }
}

#if DEBUG
#Preview {
    FormationFieldView(
        formationKey: FormationCatalog.defaultFormationKey,
        members: TeamPreviewData.members,
        assignments: TeamPreviewData.fieldAssignments,
        onPositionTapped: { _ in }
    )
    .padding()
    .teamPreviewEnvironment()
}

#Preview("Banc") {
    SubstitutesBenchView(
        members: TeamPreviewData.members,
        substituteMemberIds: ["user-2", nil, nil],
        onBenchSlotTapped: { _ in }
    )
    .padding()
    .teamPreviewEnvironment()
}
#endif
