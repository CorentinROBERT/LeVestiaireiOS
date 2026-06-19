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

    private enum Marker {
        static let scale: CGFloat = 1.5
        static let circleSize: CGFloat = 34 * scale
        static let stackSpacing: CGFloat = 4 * scale
        static let initialsFontSize: CGFloat = 11 * scale
        static let nameFontSize: CGFloat = 9 * scale
        static let nameHorizontalPadding: CGFloat = 6 * scale
        static let nameVerticalPadding: CGFloat = 2 * scale
        static let nameMaxWidth: CGFloat = 80 * scale
        static let nameBorderWidth: CGFloat = 0.5 * scale
        static let nameShadowRadius: CGFloat = 2 * scale
    }

    private var formation: FormationTemplate {
        FormationCatalog.template(for: formationKey) ?? FormationCatalog.all[0]
    }

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                RoundedRectangle(cornerRadius: 16)
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

                FieldLinesView()
                    .padding(8)

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
        .aspectRatio(0.68, contentMode: .fit)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    @ViewBuilder
    private func positionButton(position: FormationPosition, member: TeamMember?) -> some View {
        Button {
            onPositionTapped(position.id)
        } label: {
            VStack(spacing: Marker.stackSpacing) {
                ZStack {
                    Circle()
                        .fill(member == nil ? Color.white.opacity(0.92) : AppPalette.Primary.main)
                        .frame(width: Marker.circleSize, height: Marker.circleSize)
                    Text(member?.initials ?? position.localizedMarkerLabel)
                        .font(.system(size: Marker.initialsFontSize, weight: .bold))
                        .foregroundStyle(member == nil ? AppPalette.Primary.dark : .white)
                        .lineLimit(1)
                        .minimumScaleFactor(0.65)
                }

                if let member {
                    Text(member.displayName)
                        .font(.system(size: Marker.nameFontSize, weight: .semibold))
                        .foregroundStyle(.white)
                        .lineLimit(1)
                        .minimumScaleFactor(0.75)
                        .padding(.horizontal, Marker.nameHorizontalPadding)
                        .padding(.vertical, Marker.nameVerticalPadding)
                        .background {
                            Capsule()
                                .fill(.black.opacity(0.62))
                                .overlay {
                                    Capsule()
                                        .strokeBorder(
                                            .white.opacity(0.18),
                                            lineWidth: Marker.nameBorderWidth
                                        )
                                }
                        }
                        .shadow(
                            color: .black.opacity(0.35),
                            radius: Marker.nameShadowRadius,
                            y: 1
                        )
                        .frame(maxWidth: Marker.nameMaxWidth)
                }
            }
        }
        .buttonStyle(.plain)
    }

    private func member(for positionId: String) -> TeamMember? {
        guard let memberId = assignments[positionId] else { return nil }
        return members.first { $0.id == memberId || $0.userId == memberId }
    }
}

struct SubstitutesBenchView: View {
    let members: [TeamMember]
    let substituteMemberIds: [String?]
    let onBenchSlotTapped: (Int) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(L10n.text("compositionSubstitutes"))
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(AppPalette.Neutral.textPrimary)

            HStack(spacing: 10) {
                ForEach(substituteMemberIds.indices, id: \.self) { index in
                    benchSlot(index: index)
                }
            }
        }
    }

    @ViewBuilder
    private func benchSlot(index: Int) -> some View {
        let memberId = substituteMemberIds[index]
        let member = members.first { $0.id == memberId || $0.userId == memberId }

        Button {
            onBenchSlotTapped(index)
        } label: {
            VStack(spacing: 6) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(AppPalette.Neutral.surface.opacity(0.8))
                        .frame(height: 56)
                    if let member {
                        Text(member.initials)
                            .font(.subheadline.weight(.bold))
                            .foregroundStyle(AppPalette.Primary.main)
                    } else {
                        Image(systemName: "plus")
                            .foregroundStyle(AppPalette.Neutral.textSecondary)
                    }
                }

                Text(member?.displayName ?? L10n.text("select"))
                    .font(.caption2)
                    .foregroundStyle(AppPalette.Neutral.textSecondary)
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity)
        }
            .buttonStyle(.plain)
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
