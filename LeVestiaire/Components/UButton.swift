//
//  UButton.swift
//  LeVestaire
//

import SwiftUI

struct OptionalAccessibilityIdentifier: ViewModifier {
    let identifier: String?

    func body(content: Content) -> some View {
        if let identifier, !identifier.isEmpty {
            content.accessibilityIdentifier(identifier)
        } else {
            content
        }
    }
}

struct UButton: View {
    var text: String = ""
    var textColor: Color = AppPalette.Primary.onMain
    var backgroundColor: Color = AppPalette.Primary.main
    var cornerRadius: CGFloat = 12
    var isFullWidth: Bool = false
    var leadingIcon: String?
    var trailingIcon: String?
    var accessibilityLabel: String?
    var accessibilityIdentifier: String?
    var onPress: () -> Void = {}

    var body: some View {
        Button(action: onPress) {
            HStack(spacing: 8) {
                if let leadingIcon {
                    Image(systemName: leadingIcon)
                }

                Text(text)

                if isFullWidth, trailingIcon != nil {
                    Spacer()
                }

                if let trailingIcon {
                    Image(systemName: trailingIcon)
                }
            }
            .frame(maxWidth: isFullWidth ? .infinity : nil)
            .padding(.horizontal, 20)
            .padding(.vertical, 15)
            .foregroundStyle(textColor)
            .background(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(backgroundColor)
            )
            .contentShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
        }
        .buttonStyle(.fullTap)
        .accessibilityLabel(accessibilityLabel ?? text)
        .modifier(OptionalAccessibilityIdentifier(identifier: accessibilityIdentifier))
    }
}

#Preview {
    UButton(
        text: "Button",
        leadingIcon: "plus",
        trailingIcon: "chevron.right"
    )
    .padding()
}
