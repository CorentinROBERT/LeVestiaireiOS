//
//  RemoteSettingsService.swift
//  LeVestaire
//

import Combine
import FirebaseDatabase
import Foundation

@MainActor
final class RemoteSettingsService: ObservableObject {
    static let shared = RemoteSettingsService()

    private static let settingsPath = "appSettings/ios"

    @Published private(set) var settings = AppRemoteSettings.default
    @Published private(set) var hasLoadedSettings = false

    private var observerHandle: DatabaseHandle?
    private let database: Database

    init(database: Database = Database.database()) {
        self.database = database
    }

    var requiresForceUpdate: Bool {
        settings.shouldForceUpdate
    }

    var isMaintenanceMode: Bool {
        settings.isMaintenanceEnabled
    }

    var forceUpdateStoreURL: URL? {
        guard let storeURL = settings.forceUpdate?.storeURL else { return nil }
        return URL(string: storeURL)
    }

    func localizedForceUpdateMessage(language: AppLanguage) -> String {
        let remoteMessage = settings.forceUpdate?.message?.resolved(for: language)?
            .trimmingCharacters(in: .whitespacesAndNewlines)
        if let remoteMessage, !remoteMessage.isEmpty {
            return remoteMessage
        }
        return L10n.forceUpdateDefaultMessage
    }

    func localizedMaintenanceMessage(language: AppLanguage) -> String {
        let remoteMessage = settings.maintenance?.message?.resolved(for: language)?
            .trimmingCharacters(in: .whitespacesAndNewlines)
        if let remoteMessage, !remoteMessage.isEmpty {
            return remoteMessage
        }
        return L10n.maintenanceDefaultMessage
    }

    func start() {
        guard observerHandle == nil else { return }

        let reference = database.reference(withPath: Self.settingsPath)
        observerHandle = reference.observe(.value) { [weak self] snapshot in
            Task { @MainActor in
                self?.applySnapshot(snapshot)
            }
        }
    }

    func stop() {
        guard let observerHandle else { return }
        database.reference(withPath: Self.settingsPath).removeObserver(withHandle: observerHandle)
        self.observerHandle = nil
    }

    private func applySnapshot(_ snapshot: DataSnapshot) {
        defer { hasLoadedSettings = true }

        guard snapshot.exists(),
              let settings = AppRemoteSettings(snapshotValue: snapshot.value) else {
            settings = .default
            return
        }

        self.settings = settings
    }
}
