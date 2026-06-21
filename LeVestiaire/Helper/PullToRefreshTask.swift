//
//  PullToRefreshTask.swift
//  LeVestaire
//

import Foundation

/// Exécute un refresh déclenché par `.refreshable` hors de l'annulation du geste SwiftUI.
///
/// SwiftUI annule la tâche du `.refreshable` dès que le geste se termine, ce qui coupe
/// `URLSession.data(for:)` si le réseau tourne dans la même hiérarchie de tâches.
/// Le travail réseau doit donc vivre dans une `Task.detached`, attendue via
/// `withTaskCancellationHandler` pour ne pas propager l'annulation du geste.
@MainActor
final class PullToRefreshTask {
    private var inFlight: Task<Void, Never>?

    func perform(_ operation: @MainActor @escaping () async -> Void) async {
        if let inFlight {
            await waitForRefreshTask(inFlight)
        }

        var task: Task<Void, Never>!
        task = Task.detached(priority: .userInitiated) { @MainActor [weak self] in
            await operation()
            if self?.inFlight == task {
                self?.inFlight = nil
            }
        }
        inFlight = task

        await waitForRefreshTask(task)
    }

    private func waitForRefreshTask(_ task: Task<Void, Never>) async {
        await withTaskCancellationHandler {
            await task.value
        } onCancel: {
            // Ne pas annuler la Task.detached : le réseau doit aller au bout.
        }
    }
}
