//
//  TeamSeasonPicker.swift
//  LeVestaire
//

import SwiftUI

struct TeamSeasonPicker: View {
    let availableSeasons: [String]
    @Binding var selection: String
    let onChange: () -> Void

    var body: some View {
        HStack {
            Text(L10n.season)
                .font(.subheadline.weight(.semibold))
            Spacer()
            Picker(L10n.season, selection: $selection) {
                ForEach(availableSeasons, id: \.self) { season in
                    Text(SeasonFormatter.shortLabel(for: season)).tag(season)
                }
            }
            .labelsHidden()
            .pickerStyle(.menu)
            .accessibilityLabel(L10n.season)
            .accessibilityValue(SeasonFormatter.shortLabel(for: selection))
            .onChange(of: selection) { _, _ in onChange() }
        }
    }
}
