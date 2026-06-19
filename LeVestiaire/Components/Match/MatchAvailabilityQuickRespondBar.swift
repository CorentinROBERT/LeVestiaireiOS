//
//  MatchAvailabilityQuickRespondBar.swift
//  LeVestaire
//

import SwiftUI

struct MatchAvailabilityQuickRespondBar: View {
    let selectedStatus: MatchAvailabilityStatus?
    let isSubmitting: Bool
    let onSelect: (MatchAvailabilityStatus) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(L10n.indicateYourAvailability)
                .font(.caption.weight(.semibold))
                .foregroundStyle(AppPalette.Neutral.textPrimary)

            if let selectedStatus {
                Text(L10n.myAvailabilityResponse(selectedStatus.displayName))
                    .font(.caption2)
                    .foregroundStyle(AppPalette.Neutral.textSecondary)
            }

            HStack(spacing: 8) {
                ForEach(MatchAvailabilityStatus.allCases, id: \.self) { status in
                    availabilityChip(status)
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .glassEffect(.regular, in: .rect(cornerRadius: 14))
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
    }
}

#if DEBUG
#Preview {
    MatchAvailabilityQuickRespondBar(
        selectedStatus: .available,
        isSubmitting: false,
        onSelect: { _ in }
    )
    .padding()
    .teamPreviewEnvironment()
}
#endif
