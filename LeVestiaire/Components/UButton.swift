//
//  UButton.swift
//  LeVestaire
//

import SwiftUI

struct UButton: View {
    var text: String = ""
    var textColor: Color = AppPalette.Primary.onMain
    var backgroundColor: Color = AppPalette.Primary.main
    var cornerRadius: CGFloat = 12
    var isFullWidth: Bool = false
    var leadingIcon: String?
    var trailingIcon: String?
    var accessibilityLabel: String?
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
        }
        .buttonStyle(.plain)
        .accessibilityLabel(accessibilityLabel ?? text)
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
