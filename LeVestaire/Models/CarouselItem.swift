//
//  CarouselItem.swift
//  LeVestaire
//
//  Created by Corentin Robert on 09/06/2026.
//

import SwiftUI
import Foundation

struct CarouselItem: Identifiable {
    let id = UUID()
    let title: String
    let imageSource: String
    let subtitle: String?
    let buttonTitle: String?
    let backgroundColor: Color
    let onButtonPress: () -> Void

    init(
        title: String,
        imageSource: String,
        subtitle: String? = nil,
        buttonTitle: String? = nil,
        backgroundColor: Color = .black,
        onButtonPress: @escaping () -> Void = {}
    ) {
        self.title = title
        self.imageSource = imageSource
        self.subtitle = subtitle
        self.buttonTitle = buttonTitle
        self.backgroundColor = backgroundColor
        self.onButtonPress = onButtonPress
    }
}
