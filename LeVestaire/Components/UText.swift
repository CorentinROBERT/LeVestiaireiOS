//
//  Text.swift
//  LeVestaire
//
//  Created by Corentin Robert on 08/06/2026.
//

import SwiftUI

enum UTextType {
    case title
    case `default`
    case description

    var font: Font {
        switch self {
        case .title:
            return .largeTitle.weight(.bold)
        case .default:
            return .body
        case .description:
            return .subheadline
        }
    }

    var foregroundColor: Color {
        switch self {
        case .title:
            return .primary
        case .default:
            return .primary
        case .description:
            return .secondary
        }
    }
}

struct UText: View {
    var text: String
    var type: UTextType = .default
    var foregroundColor: Color? = nil
    var backgroundColor: Color? = nil
    var cornerRadius: CGFloat = 0.0
    var padding: CGFloat = 0.0

    var body: some View {
        Text(text)
            .font(type.font)
            .foregroundStyle(foregroundColor ?? type.foregroundColor)
            .padding(padding)
            .background(backgroundColor)
            .cornerRadius(cornerRadius)
    }
}

#Preview {
    VStack(alignment: .leading, spacing: 12) {
        UText(text: "Titre", type: .title)
        UText(text: "Texte par defaut")
        UText(text: "Description", type: .description)
    }
    .padding()
}
