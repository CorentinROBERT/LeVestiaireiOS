//
//  TaskCancellationTests.swift
//  LeVestiaireTests
//

import Foundation
import Testing
@testable import LeVestiaire

struct TaskCancellationTests {

    @Test
    func isError_detectsCancellationError() {
        #expect(TaskCancellation.isError(CancellationError()))
    }

    @Test
    func isError_detectsCancelledURLError() {
        #expect(TaskCancellation.isError(URLError(.cancelled)))
    }

    @Test
    func isError_ignoresOtherErrors() {
        struct SampleError: Error {}
        #expect(!TaskCancellation.isError(SampleError()))
        #expect(!TaskCancellation.isError(URLError(.notConnectedToInternet)))
    }
}
