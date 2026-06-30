//
//  AsyncTestSupport.swift
//  LeVestiaireTests
//

import Foundation
import Testing

enum AsyncTestSupport {
    /// Attend qu'une condition MainActor devienne vraie, en relâchant l'acteur entre chaque
    /// poll pour laisser les `Task { }` lancés par les ViewModels s'exécuter (CI plus lente).
    nonisolated static func waitUntil(
        _ condition: @escaping @MainActor () -> Bool,
        timeout: Duration = .seconds(10)
    ) async {
        let clock = ContinuousClock()
        let deadline = clock.now + timeout

        while await MainActor.run(body: condition) == false {
            if clock.now >= deadline {
                await MainActor.run {
                    Issue.record("Condition non satisfaite avant expiration du délai.")
                }
                return
            }
            await Task.yield()
            try? await Task.sleep(for: .milliseconds(25))
        }
    }
}
