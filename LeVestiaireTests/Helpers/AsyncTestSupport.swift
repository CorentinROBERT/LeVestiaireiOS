//
//  AsyncTestSupport.swift
//  LeVestiaireTests
//

import Foundation
import Testing

enum AsyncTestSupport {
    static func waitUntil(
        _ condition: @escaping @MainActor () -> Bool,
        timeout: Duration = .seconds(5)
    ) async {
    let clock = ContinuousClock()
    let deadline = clock.now + timeout

    while await condition() == false {
      if clock.now >= deadline {
        Issue.record("Condition non satisfaite avant expiration du délai.")
        return
      }
      await Task.yield()
      try? await Task.sleep(for: .milliseconds(10))
    }
  }
}
