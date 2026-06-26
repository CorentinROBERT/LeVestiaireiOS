//
//  UGlassFormRow.swift
//  LeVestaire
//
//  Created by Corentin Robert on 14/06/2026.
//

import SwiftUI

struct UGlassFormRow<Content: View>: View {
    let icon: String
    @ViewBuilder let content: () -> Content

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.body.weight(.semibold))
                .foregroundStyle(AppPalette.Primary.light)
                .frame(width: 22)

            content()
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 12)
        .glassEffect(.regular, in: .rect(cornerRadius: 18))
        .clipShape(RoundedRectangle(cornerRadius: 18))
    }
}

#Preview {
    
    ZStack{
        AuthScreenBackground()
        UGlassFormRow(icon: "house", content: {
            Text("coucou")
        })
    }
}
