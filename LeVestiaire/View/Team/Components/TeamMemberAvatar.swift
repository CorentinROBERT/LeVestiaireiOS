//
//  TeamMemberAvatar.swift
//  LeVestaire
//

import SwiftUI

struct TeamMemberAvatar: View {
    let initials: String
    var size: CGFloat = 40

    var body: some View {
        Circle()
            .fill(AppPalette.Primary.soft)
            .frame(width: size, height: size)
            .overlay {
                Text(initials)
                    .font(size > 44 ? .subheadline.weight(.bold) : .caption.weight(.bold))
                    .foregroundStyle(AppPalette.Primary.main)
            }
            .accessibilityHidden(true)
    }
}
