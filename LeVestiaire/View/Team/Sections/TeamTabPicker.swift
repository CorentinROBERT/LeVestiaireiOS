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
        .onChange(of: selection) { _, _ in
            TeamHaptics.lightImpact()
        }
    }
}
