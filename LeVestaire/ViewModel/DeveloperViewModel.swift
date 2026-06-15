//
//  DeveloperViewModel.swift
//  LeVestaire
//
//  Created by Corentin Robert on 12/06/2026.
//

import Combine
import Foundation

enum APITestState: Equatable {
    case idle
    case loading
    case success(statusCode: Int, durationMs: Int)
    case failure(message: String)
}

final class DeveloperViewModel: ObservableObject {
    @Published var selectedEnvironment: APIEnvironment
    @Published var customBaseURL: String
    @Published var apiTestState: APITestState = .idle

    private let configuration: APIConfiguration
    private var cancellables = Set<AnyCancellable>()

    init(configuration: APIConfiguration = .shared) {
        self.configuration = configuration
        self.selectedEnvironment = configuration.environment
        self.customBaseURL = configuration.customBaseURL

        $selectedEnvironment
            .dropFirst()
            .sink { [weak self] environment in
                self?.configuration.environment = environment
                self?.resetAPITestState()
            }
            .store(in: &cancellables)

        $customBaseURL
            .dropFirst()
            .sink { [weak self] url in
                self?.configuration.customBaseURL = url
                self?.resetAPITestState()
            }
            .store(in: &cancellables)
    }

    var resolvedBaseURL: String {
        configuration.resolvedBaseURL
    }

    var healthCheckURL: String? {
        configuration.healthCheckURL
    }

    var isCustomEnvironment: Bool {
        selectedEnvironment == .custom
    }

    var appVersion: String {
        AppInfo.version
    }

    var appBuildNumber: String {
        AppInfo.buildNumber
    }

    var canTestAPI: Bool {
        healthCheckURL != nil && apiTestState != .loading
    }

    func testAPI() {
        guard canTestAPI else { return }

        apiTestState = .loading

        Task {
            await runAPITest()
        }
    }

    @MainActor
    private func runAPITest() async {
        guard let healthCheckURL else {
            apiTestState = .failure(message: APITestError.invalidURL.errorDescription ?? "URL invalide.")
            return
        }

        do {
            let result = try await APITester.test(urlString: healthCheckURL)
            apiTestState = .success(
                statusCode: result.statusCode,
                durationMs: result.durationMs
            )
        } catch {
            apiTestState = .failure(message: error.localizedDescription)
        }
    }

    private func resetAPITestState() {
        apiTestState = .idle
    }
}
