//
//  UKPIHome.swift
//  Health
//
//  Created by Corentin Robert on 23/04/2026.
//

import SwiftUI

struct UKPIHome: View {
    let title: String
    let value: String
    let subtitle: String?
    let systemImage: String
    let iconTint: Color

    init(title: String, value: String, subtitle: String? = nil, systemImage: String, iconTint: Color) {
        self.title = title
        self.value = value
        self.subtitle = subtitle
        self.systemImage = systemImage
        self.iconTint = iconTint
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 12) {
                Image(systemName: systemImage)
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(iconTint)
                    .frame(width: 44, height: 44)
                    .background(iconTint.opacity(0.14), in: RoundedRectangle(cornerRadius: 14, style: .continuous))

                Spacer()
            }

            VStack(alignment: .leading, spacing: 6) {
                Text(title)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                Text(value)
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundStyle(.primary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)

                if let subtitle, !subtitle.isEmpty {
                    Text(subtitle)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .frame(maxWidth: .infinity, minHeight: 160, alignment: .topLeading)
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(.regularMaterial)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .strokeBorder(.white.opacity(0.22), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.06), radius: 18, y: 10)
    }
}

#Preview {
    UKPIHome(
        title: "Calories",
        value: "1 840 kcal",
        subtitle: "Consommees aujourd'hui",
        systemImage: "flame.fill",
        iconTint: .orange
    )
    .padding()
    .background(Color(.systemGroupedBackground))
}
