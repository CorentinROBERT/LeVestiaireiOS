//
//  Matchs.swift
//  LeVestaire
//
//  Created by Corentin Robert on 15/06/2026.
//

import SwiftUI

struct Matchs: View {
    @EnvironmentObject private var authService: AuthService

    var body: some View {
        VStack(spacing: 16) {
            Text("Hello, World!")

            UButton(text: "Disconnect", onPress: {
                Task {
                    await authService.logout()
                }
            })
        }
    }
}

#Preview {
    Matchs()
        .environmentObject(AuthService.shared)
}
