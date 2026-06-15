//
//  UCard.swift
//  LeVestaire
//
//  Created by Corentin Robert on 14/06/2026.
//

import SwiftUI

struct UCard<Content: View>: View {
    let title: String?
    let icon: String?
    let iconTint: Color
    let cornerRadius: CGFloat
    let padding: CGFloat
    @ViewBuilder let content: () -> Content

    init(
        title: String? = nil,
        icon: String? = nil,
        iconTint: Color = AppPalette.Primary.main,
        cornerRadius: CGFloat = 20,
        padding: CGFloat = 20,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.title = title
        self.icon = icon
        self.iconTint = iconTint
        self.cornerRadius = cornerRadius
        self.padding = padding
        self.content = content
    }

    var body: some View {
        VStack(alignment: .leading, spacing: title == nil ? 0 : 14) {
            if let title {
                HStack(spacing: 10) {
                    if let icon {
                        Image(systemName: icon)
                            .foregroundStyle(iconTint)
                    }

                    Text(title)
                        .font(.headline)
                        .foregroundStyle(AppPalette.Primary.dark)
                }
            }

            content()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(padding)
        .glassEffect(.regular, in: .rect(cornerRadius: cornerRadius))
    }
}

#Preview {
    ZStack {
        AuthScreenBackground()

        VStack(spacing: 20) {
            UCard(title: "Informations", icon: "info.circle.fill") {
                Text("Contenu de la card avec titre et icône.")
                    .font(.subheadline)
                    .foregroundStyle(AppPalette.Neutral.textSecondary)
            }

            UCard {
                Text("Card simple sans en-tête.")
                    .font(.subheadline)
                    .foregroundStyle(AppPalette.Neutral.textPrimary)
            }
        }
        .padding(24)
    }
}
