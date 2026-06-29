//
//  MatchDetailTabPicker.swift
//  LeVestaire
//

import SwiftUI

struct MatchDetailTabPicker: View {
    let tabs: [MatchDetailTab]
    @Binding var selection: MatchDetailTab

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(tabs) { tab in
                    Button {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            selection = tab
                        }
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: tab.icon)
                                .font(.caption.weight(.semibold))

                            Text(tab.title)
                                .font(.caption.weight(.semibold))
                                .lineLimit(1)
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background {
                            Capsule()
                                .fill(
                                    selection == tab
                                        ? AppPalette.Primary.main
                                        : AppPalette.Neutral.surface
                                )
                        }
                        .foregroundStyle(
                            selection == tab
                                ? AppPalette.Primary.onMain
                                : AppPalette.Neutral.textPrimary
                        )
                    }
                    .buttonStyle(.fullTap)
                    .accessibilityLabel(tab.title)
                    .accessibilityAddTraits(selection == tab ? .isSelected : [])
                }
            }
        }
        .accessibilityIdentifier(AccessibilityID.Match.tabPicker)
    }
}

#if DEBUG
#Preview {
    MatchDetailTabPicker(
        tabs: [.composition, .events, .statistics, .quiz],
        selection: .constant(.composition)
    )
    .padding()
    .teamPreviewEnvironment()
}
#endif
