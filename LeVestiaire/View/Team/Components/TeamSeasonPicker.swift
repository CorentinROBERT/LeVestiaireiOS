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
        UMenuPicker(
            title: L10n.season,
            selection: $selection,
            selectionLabel: { SeasonFormatter.shortLabel(for: $0) },
            accessibilityValue: SeasonFormatter.fullLabel(for: selection),
            onChange: onChange
        ) {
            ForEach(availableSeasons, id: \.self) { season in
                Text(SeasonFormatter.shortLabel(for: season)).tag(season)
            }
        }
    }
}
