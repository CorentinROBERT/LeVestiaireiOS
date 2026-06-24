//
//  TeamPreviewEnvironment.swift
//  LeVestaire
//

#if DEBUG
import SwiftUI

extension View {
    func teamPreviewEnvironment() -> some View {
        self
            .environmentObject(LocalizationManager.shared)
            .environmentObject(MainTabViewModel())
            .environment(\.locale, LocalizationManager.shared.locale)
            .background(AuthScreenBackground())
    }
}
#endif
