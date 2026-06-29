//
//  DeveloperViewModelTests.swift
//  LeVestiaireTests
//

import Foundation
import Testing
@testable import LeVestiaire

@MainActor
struct DeveloperViewModelTests {
  @Test
  func isCustomEnvironment_reflectsSelectedEnvironment() {
    let configuration = MockAPIConfiguration()
    let viewModel = DeveloperViewModel(
      configuration: configuration,
      pushNotificationManager: MockPushNotificationManager()
    )

    #expect(viewModel.isCustomEnvironment == false)

    viewModel.selectedEnvironment = .custom
    #expect(viewModel.isCustomEnvironment)
  }

  @Test
  func changingEnvironment_resetsAPITestState() {
    let configuration = MockAPIConfiguration()
    let viewModel = DeveloperViewModel(
      configuration: configuration,
      pushNotificationManager: MockPushNotificationManager()
    )
    viewModel.apiTestState = .success(statusCode: 200, durationMs: 10)

    viewModel.selectedEnvironment = .production

    #expect(viewModel.apiTestState == .idle)
  }

  @Test
  func sendTestPushNotification_setsSuccessState() async {
    let pushManager = MockPushNotificationManager()
    let viewModel = DeveloperViewModel(
      configuration: MockAPIConfiguration(),
      pushNotificationManager: pushManager
    )

    viewModel.sendTestPushNotification()
    await AsyncTestSupport.waitUntil {
      if case .success = viewModel.pushTestState { return true }
      return false
    }

    #expect(pushManager.sendTestPushCallCount == 1)
    if case .success = viewModel.pushTestState {
      #expect(Bool(true))
    } else {
      Issue.record("État push inattendu")
    }
  }

  @Test
  func sendTestPushNotification_setsFailureStateOnError() async {
    let pushManager = MockPushNotificationManager()
    pushManager.sendTestPushHandler = { _ in
      throw NSError(domain: "test", code: 1)
    }
    let viewModel = DeveloperViewModel(
      configuration: MockAPIConfiguration(),
      pushNotificationManager: pushManager
    )

    viewModel.sendTestPushNotification()
    await AsyncTestSupport.waitUntil {
      if case .failure = viewModel.pushTestState { return true }
      return false
    }

    if case .failure = viewModel.pushTestState {
      #expect(Bool(true))
    } else {
      Issue.record("État push inattendu")
    }
  }
}
