//
//  TeamToastBanner.swift
//  LeVestaire
//

import SwiftUI

struct TeamToastBanner: View {
    enum Style {
        case success
        case error
    }

    let message: String
    var style: Style = .success

    private var accentColor: Color {
        switch style {
        case .success:
            return AppPalette.Semantic.success
        case .error:
            return AppPalette.Semantic.error
        }
    }

    private var iconName: String {
        switch style {
        case .success:
            return "checkmark.circle.fill"
        case .error:
            return "exclamationmark.triangle.fill"
        }
    }

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: iconName)
                .font(.body.weight(.semibold))
                .foregroundStyle(accentColor)
                .padding(.top, 1)

            Text(message)
                .font(.subheadline.weight(.medium))
                .foregroundStyle(AppPalette.Neutral.textPrimary)
                .multilineTextAlignment(.leading)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(AppPalette.Neutral.surface, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(accentColor.opacity(0.45), lineWidth: 1)
        }
        .shadow(color: Color.black.opacity(0.14), radius: 10, y: 4)
        .padding(.horizontal, 20)
        .padding(.bottom, 12)
    }
}
