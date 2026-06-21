//
//  TeamTabPicker.swift
//  LeVestaire
//

import SwiftUI

struct TeamTabPicker: View {
    @Binding var selection: TeamContentTab

    var body: some View {
        Picker("", selection: $selection) {
            ForEach(TeamContentTab.allCases) { tab in
                Text(tab.title).tag(tab)
            }
        }
        .pickerStyle(.segmented)
        .accessibilityValue(selection.title)
        .onChange(of: selection) { _, newValue in
            TeamHaptics.lightImpact()
            _ = newValue
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
