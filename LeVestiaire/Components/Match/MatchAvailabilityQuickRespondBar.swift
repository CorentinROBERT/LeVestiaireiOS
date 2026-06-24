//
//  MatchAvailabilityQuickRespondBar.swift
//  LeVestaire
//

import SwiftUI

struct MatchAvailabilityQuickRespondBar: View {
    enum LayoutStyle {
        case standalone
        case embedded
    }

    let matchContext: String?
    let selectedStatus: MatchAvailabilityStatus?
    let isSubmitting: Bool
    let layout: LayoutStyle
    let onSelect: (MatchAvailabilityStatus) -> Void

    init(
        matchContext: String? = nil,
        selectedStatus: MatchAvailabilityStatus?,
        isSubmitting: Bool,
        layout: LayoutStyle = .standalone,
        onSelect: @escaping (MatchAvailabilityStatus) -> Void
    ) {
        self.matchContext = matchContext
        self.selectedStatus = selectedStatus
        self.isSubmitting = isSubmitting
        self.layout = layout
        self.onSelect = onSelect
    }

    var body: some View {
        Group {
            switch layout {
            case .standalone:
                standaloneBody
            case .embedded:
                embeddedBody
            }
        }
    }

    private var standaloneBody: some View {
        content
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .glassEffect(.regular, in: .rect(cornerRadius: 14))
    }

    private var embeddedBody: some View {
        VStack(spacing: 0) {
            Divider()
                .overlay(AppPalette.Neutral.textTertiary.opacity(0.25))

            content
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(AppPalette.Primary.main.opacity(0.06))
        }
    }

    private var content: some View {
        VStack(alignment: .leading, spacing: 10) {
            header

            HStack(spacing: 8) {
                ForEach(MatchAvailabilityStatus.allCases, id: \.self) { status in
                    availabilityChip(status)
                }
            }
        }
    }

    private var header: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: "hand.raised.fill")
                .font(.caption.weight(.semibold))
                .foregroundStyle(AppPalette.Primary.main)
                .frame(width: 28, height: 28)
                .background(
                    Circle()
                        .fill(AppPalette.Primary.main.opacity(0.12))
                )

            VStack(alignment: .leading, spacing: 2) {
                Text(L10n.indicateYourAvailability)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(AppPalette.Neutral.textPrimary)

                if let matchContext, !matchContext.isEmpty {
                    Text(matchContext)
                        .font(.caption2)
                        .foregroundStyle(AppPalette.Neutral.textSecondary)
                        .lineLimit(1)
                }

                if let selectedStatus {
                    Text(L10n.myAvailabilityResponse(selectedStatus.displayName))
                        .font(.caption2.weight(.medium))
                        .foregroundStyle(AppPalette.Primary.main)
                }
            }

            Spacer(minLength: 0)
        }
    }

    private func availabilityChip(_ status: MatchAvailabilityStatus) -> some View {
        let isSelected = selectedStatus == status

        return Button {
            onSelect(status)
        } label: {
            Text(status.displayName)
                .font(.caption.weight(.semibold))
                .foregroundStyle(isSelected ? AppPalette.Primary.onMain : AppPalette.Primary.main)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .frame(maxWidth: .infinity)
                .background(
                    Capsule()
                        .fill(isSelected ? AppPalette.Primary.main : AppPalette.Primary.soft)
                )
        }
        .buttonStyle(.plain)
        .disabled(isSubmitting)
        .opacity(isSubmitting ? 0.7 : 1)
    }
}

#if DEBUG
#Preview("Standalone") {
    MatchAvailabilityQuickRespondBar(
        selectedStatus: .available,
        isSubmitting: false,
        onSelect: { _ in }
    )
    .padding()
    .teamPreviewEnvironment()
}

#Preview("Embedded") {
    MatchAvailabilityQuickRespondBar(
        matchContext: "sam. 21 juin · 20:00",
        selectedStatus: .available,
        isSubmitting: false,
        layout: .embedded,
        onSelect: { _ in }
    )
    .clipShape(RoundedRectangle(cornerRadius: 16))
    .padding()
    .teamPreviewEnvironment()
}
#endif
