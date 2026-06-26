//
//  UFullTapButtonStyle.swift
//  LeVestaire
//

import SwiftUI

/// Bouton plain dont toute la surface visible (padding, fond, frame) est cliquable.
struct UFullTapButtonStyle: ButtonStyle {
    var pressedOpacity: Double = 0.92

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .contentShape(Rectangle())
            .opacity(configuration.isPressed ? pressedOpacity : 1)
    }
}

extension ButtonStyle where Self == UFullTapButtonStyle {
    static var fullTap: UFullTapButtonStyle { UFullTapButtonStyle() }
}

extension View {
    /// Étend la zone cliquable à toute la surface du composant.
    func fullTapTarget(cornerRadius: CGFloat? = nil) -> some View {
        contentShape(
            cornerRadius.map {
                AnyShape(RoundedRectangle(cornerRadius: $0, style: .continuous))
            } ?? AnyShape(Rectangle())
        )
    }
}
