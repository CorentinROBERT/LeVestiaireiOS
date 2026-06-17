//
//  MatchFiltersSheet.swift
//  LeVestaire
//
//  Created by Corentin Robert on 17/06/2026.
//

import SwiftUI

struct MatchFiltersSheet: View {
    @Binding var filters: MatchFilters
    let onApply: () -> Void
    let onReset: () -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var draftFilters: MatchFilters
    @State private var sheetHeight: CGFloat = 380

    init(
        filters: Binding<MatchFilters>,
        onApply: @escaping () -> Void,
        onReset: @escaping () -> Void
    ) {
        _filters = filters
        self.onApply = onApply
        self.onReset = onReset
        _draftFilters = State(initialValue: filters.wrappedValue)
    }

    var body: some View {
        VStack(spacing: 0) {
            sheetHeader

            VStack(alignment: .leading, spacing: 24) {
                statusSection
                periodSection
                actionButtons
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 20)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.top, 8)
        .background {
            GeometryReader { geometry in
                Color.clear.preference(
                    key: SheetContentHeightPreferenceKey.self,
                    value: geometry.size.height
                )
            }
        }
        .onPreferenceChange(SheetContentHeightPreferenceKey.self) { height in
            guard height > 0 else { return }
            sheetHeight = height
        }
        .presentationDetents([.height(sheetHeight)])
        .presentationDragIndicator(.visible)
    }

    private var sheetHeader: some View {
        HStack(alignment: .center) {
            Text(L10n.filterMatches)
                .font(.headline)
                .foregroundStyle(AppPalette.Neutral.textPrimary)

            Spacer()

            Button(L10n.close) {
                dismiss()
            }
            .font(.subheadline.weight(.semibold))
        }
        .padding(.horizontal, 20)
        .padding(.top, 28)
        .padding(.bottom, 12)
    }

    private var statusSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(L10n.filterStatusLabel)
                .font(.headline)
                .foregroundStyle(AppPalette.Neutral.textPrimary)

            FlowLayout(spacing: 8) {
                ForEach(MatchStatus.allCases) { status in
                    let isSelected = draftFilters.statuses.contains(status)
                    Button {
                        toggleStatus(status)
                    } label: {
                        Text(status.displayName)
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(isSelected ? AppPalette.Primary.onMain : AppPalette.Primary.main)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(
                                Capsule()
                                    .fill(isSelected ? AppPalette.Primary.main : AppPalette.Primary.soft)
                            )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private var periodSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(L10n.period)
                .font(.headline)
                .foregroundStyle(AppPalette.Neutral.textPrimary)

            HStack(spacing: 12) {
                dateField(
                    title: L10n.from,
                    date: draftFilters.fromDate,
                    binding: $draftFilters.fromDate
                )

                dateField(
                    title: L10n.to,
                    date: draftFilters.toDate,
                    binding: $draftFilters.toDate
                )
            }
        }
    }

    private var actionButtons: some View {
        HStack(spacing: 12) {
            UButton(
                text: L10n.reset,
                textColor: AppPalette.Primary.main,
                backgroundColor: AppPalette.Primary.soft,
                cornerRadius: 12,
                isFullWidth: true,
                onPress: {
                    draftFilters = MatchFilters()
                    filters = draftFilters
                    onReset()
                    dismiss()
                }
            )

            UButton(
                text: L10n.apply,
                textColor: AppPalette.Primary.onMain,
                backgroundColor: AppPalette.Primary.main,
                cornerRadius: 12,
                isFullWidth: true,
                onPress: {
                    filters = draftFilters
                    onApply()
                    dismiss()
                }
            )
        }
    }

    private func toggleStatus(_ status: MatchStatus) {
        if draftFilters.statuses.contains(status) {
            draftFilters.statuses.remove(status)
        } else {
            draftFilters.statuses.insert(status)
        }
    }

    private func dateField(
        title: String,
        date: Date?,
        binding: Binding<Date?>
    ) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundStyle(AppPalette.Neutral.textSecondary)

            DatePicker(
                "",
                selection: Binding(
                    get: { date ?? Date() },
                    set: { binding.wrappedValue = $0 }
                ),
                displayedComponents: .date
            )
            .labelsHidden()
            .datePickerStyle(.compact)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

private struct SheetContentHeightPreferenceKey: PreferenceKey {
    static var defaultValue: CGFloat = 0

    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = max(value, nextValue())
    }
}

private struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = arrangeSubviews(proposal: proposal, subviews: subviews)
        return result.size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = arrangeSubviews(proposal: proposal, subviews: subviews)
        for (index, frame) in result.frames.enumerated() {
            subviews[index].place(
                at: CGPoint(x: bounds.minX + frame.minX, y: bounds.minY + frame.minY),
                proposal: ProposedViewSize(frame.size)
            )
        }
    }

    private func arrangeSubviews(
        proposal: ProposedViewSize,
        subviews: Subviews
    ) -> (size: CGSize, frames: [CGRect]) {
        let maxWidth = proposal.width ?? .infinity
        var x: CGFloat = 0
        var y: CGFloat = 0
        var rowHeight: CGFloat = 0
        var frames: [CGRect] = []

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x + size.width > maxWidth, x > 0 {
                x = 0
                y += rowHeight + spacing
                rowHeight = 0
            }

            frames.append(CGRect(origin: CGPoint(x: x, y: y), size: size))
            rowHeight = max(rowHeight, size.height)
            x += size.width + spacing
        }

        return (CGSize(width: maxWidth, height: y + rowHeight), frames)
    }
}
