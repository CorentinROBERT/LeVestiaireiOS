//
//  CompositionTemplateAvailabilityBanner.swift
//  LeVestaire
//

import SwiftUI

struct CompositionTemplateAvailabilityBanner: View {
    let review: CompositionTemplateAvailabilityReview
    let onRemoveAbsent: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            if !review.absent.isEmpty {
                conflictSection(
                    icon: "exclamationmark.triangle.fill",
                    iconTint: AppPalette.Semantic.error,
                    title: L10n.compositionTemplateAbsentTitle(review.absent.count),
                    message: L10n.text("compositionTemplateAbsentHint"),
                    names: review.absentNames
                ) {
                    UButton(
                        text: L10n.text("compositionTemplateRemoveAbsent"),
                        textColor: AppPalette.Primary.onMain,
                        backgroundColor: AppPalette.Semantic.error,
                        cornerRadius: 10,
                        isFullWidth: true,
                        onPress: onRemoveAbsent
                    )
                }
            }

            if !review.unknown.isEmpty {
                conflictSection(
                    icon: "questionmark.circle.fill",
                    iconTint: AppPalette.Semantic.warning,
                    title: L10n.compositionTemplateUnknownTitle(review.unknown.count),
                    message: L10n.text("compositionTemplateUnknownHint"),
                    names: review.unknownNames
                )
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .glassEffect(.regular, in: .rect(cornerRadius: 14))
    }

    @ViewBuilder
    private func conflictSection<Actions: View>(
        icon: String,
        iconTint: Color,
        title: String,
        message: String,
        names: String,
        @ViewBuilder actions: () -> Actions = { EmptyView() }
    ) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Label(title, systemImage: icon)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(iconTint)
                .frame(maxWidth: .infinity, alignment: .leading)

            Text(message)
                .font(.caption)
                .foregroundStyle(AppPalette.Neutral.textSecondary)
                .frame(maxWidth: .infinity, alignment: .leading)

            Text(names)
                .font(.caption.weight(.medium))
                .foregroundStyle(AppPalette.Neutral.textPrimary)
                .frame(maxWidth: .infinity, alignment: .leading)

            actions()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

#if DEBUG
#Preview {
    CompositionTemplateAvailabilityBanner(
        review: CompositionTemplateAvailabilityReview(
            absent: [TeamPreviewData.members[0]],
            unknown: [TeamPreviewData.members[1]]
        ),
        onRemoveAbsent: {}
    )
    .padding()
    .teamPreviewEnvironment()
}
#endif
