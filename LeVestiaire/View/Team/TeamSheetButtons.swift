//
//  TeamSheetButtons.swift
//  LeVestaire
//

import SwiftUI

struct PrimarySheetButtonStyle: ButtonStyle {
    var isLoading: Bool

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(
                RoundedRectangle(cornerRadius: 18)
                    .fill(AppPalette.Primary.main)
            )
            .contentShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            .opacity(configuration.isPressed ? 0.92 : 1)
            .overlay {
                if isLoading {
                    ProgressView()
                        .tint(.white)
                }
            }
    }
}

struct SecondarySheetButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(AppPalette.Neutral.textSecondary)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .glassEffect(.regular, in: .rect(cornerRadius: 18))
            .contentShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            .opacity(configuration.isPressed ? 0.92 : 1)
    }
}

struct DestructiveSheetButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(AppPalette.Semantic.error)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .glassEffect(.regular, in: .rect(cornerRadius: 18))
            .contentShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            .opacity(configuration.isPressed ? 0.92 : 1)
    }
}

extension ButtonStyle where Self == PrimarySheetButtonStyle {
    static func primarySheet(isLoading: Bool = false) -> PrimarySheetButtonStyle {
        PrimarySheetButtonStyle(isLoading: isLoading)
    }
}

extension ButtonStyle where Self == SecondarySheetButtonStyle {
    static var secondarySheet: SecondarySheetButtonStyle { SecondarySheetButtonStyle() }
}

extension ButtonStyle where Self == DestructiveSheetButtonStyle {
    static var destructiveSheet: DestructiveSheetButtonStyle { DestructiveSheetButtonStyle() }
}

extension View {
    func secondarySheetButton() -> some View {
        buttonStyle(SecondarySheetButtonStyle())
    }

    func primarySheetButton(isLoading: Bool) -> some View {
        buttonStyle(PrimarySheetButtonStyle(isLoading: isLoading))
    }

    func destructiveSheetButton() -> some View {
        buttonStyle(DestructiveSheetButtonStyle())
    }
}
