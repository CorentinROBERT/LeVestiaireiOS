//
//  TeamTabPicker.swift
//  LeVestaire
//

import SwiftUI

struct TeamTabPicker: View {
    @Binding var selection: TeamContentTab

    var body: some View {
        USegmentedPicker(
            selection: $selection,
            accessibilityValue: selection.title,
            onChange: { _ in
                TeamHaptics.lightImpact()
            }
        ) {
            ForEach(TeamContentTab.allCases) { tab in
                Text(tab.title).tag(tab)
            }
        }
    }
}

#if DEBUG
#Preview {
    TeamTabPicker(selection: .constant(.roster))
        .padding()
        .teamPreviewEnvironment()
}
#endif
