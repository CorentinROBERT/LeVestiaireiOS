//
//  AuthScreenBackground.swift
//  LeVestaire
//
//  Created by Corentin Robert on 14/06/2026.
//

import SwiftUI

struct AuthScreenBackground: View {
    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    AppPalette.Neutral.background,
                    AppPalette.Neutral.backgroundMid,
                    AppPalette.Neutral.backgroundDeep,
                ],
                startPoint: .top,
                endPoint: .bottom
            )

            Circle()
                .fill(AppPalette.Primary.main.opacity(0.18))
                .frame(width: 300, height: 300)
                .blur(radius: 70)
                .offset(x: -130, y: -210)

            Circle()
                .fill(AppPalette.Neutral.decorativeGlow.opacity(0.9))
                .frame(width: 260, height: 260)
                .blur(radius: 60)
                .offset(x: 150, y: -40)

            Circle()
                .fill(AppPalette.Primary.main.opacity(0.12))
                .frame(width: 340, height: 340)
                .blur(radius: 80)
                .offset(x: 80, y: 280)
        }
        .ignoresSafeArea()
    }
}

#Preview{
    AuthScreenBackground()
}
