//
//  MainTabViewModel.swift
//  LeVestaire
//
//  Created by Corentin Robert on 16/06/2026.
//

import Combine
import Foundation

@MainActor
final class MainTabViewModel: ObservableObject {
    @Published var showsNotificationCenter = false

    func openNotifications() {
        showsNotificationCenter = true
    }

    func closeNotifications() {
        showsNotificationCenter = false
    }
}
