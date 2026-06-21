//
//  TeamRoleBadge.swift
//  LeVestaire
//

import SwiftUI

struct TeamRoleBadge: View {
    let role: TeamRole

    var body: some View {
        Text(role.localizedLabel)
            .font(.caption2.weight(.semibold))
            .foregroundStyle(TeamRoleStyle.color(for: role))
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(TeamRoleStyle.backgroundColor(for: role), in: Capsule())
            .accessibilityLabel(role.localizedLabel)
    }
}
