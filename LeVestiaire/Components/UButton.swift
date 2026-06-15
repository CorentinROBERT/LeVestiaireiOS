//
//  UButton.swift
//  LeVestaire
//
//  Created by Corentin Robert on 09/06/2026.
//

import SwiftUI

struct UButton: View {
    
    var text: String = ""
    var textColor: Color = .blue
    var backgroundColor: Color = .white
    var cornerRadius: CGFloat = 0.0
    var isFullWidth: Bool = false
    var leadingIcon: String? = nil
    var trailingIcon: String? = nil
    var onPress: () -> Void = {}
    
    var body: some View {
        Button {
            onPress()
        } label: {
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
    }
}

#Preview {
    UButton(
        text: "Button",
        textColor: .blue,
        backgroundColor: .black,
        cornerRadius: 25,
        leadingIcon: "plus",
        trailingIcon: "chevron.right"
    )
}
