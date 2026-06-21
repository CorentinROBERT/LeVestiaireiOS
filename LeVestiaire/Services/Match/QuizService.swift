//
//  QuizService.swift
//  LeVestaire
//

import Foundation

enum QuizServiceError: LocalizedError {
    case unauthorized
    case requestFailed(String)

    var errorDescription: String? {
        switch self {
        case .unauthorized:
            return L10n.sessionRequired
        case .requestFailed(let message):
            return message
        }
    }
}

final class QuizService {
    static let shared = QuizService(
        client: APIClient.shared,
        authService: AuthService.shared
    )

    private let client: APIClient
    private let authService: AuthService

    init(client: APIClient, authService: AuthService) {
        self.client = client
        self.authService = authService
    }

    @MainActor
    func fetchQuizzesForMatch(matchId: String) async throws -> [MatchQuizSummary] {
        let (data, response) = try await authorizedRequest(
            path: APIEndpoints.quizzesForMatch(matchId),
            method: "GET"
        )
        try validate(response: response, data: data, fallback: L10n.matchesLoading)
        return try MatchQuizDecoding.decodeList(from: data)
    }

    @MainActor
    func fetchQuiz(id: String) async throws -> MatchQuizDetail {
        let (data, response) = try await authorizedRequest(
            path: APIEndpoints.quizById(id),
            method: "GET"
        )
        try validate(response: response, data: data, fallback: L10n.matchesLoading)
        return try MatchQuizDecoding.decodeDetail(from: data)
    }

    @MainActor
    func createQuiz(matchId: String) async throws -> MatchQuizDetail {
        let (data, response) = try await authorizedRequest(
            path: APIEndpoints.createQuiz(matchId),
            method: "POST",
            body: Data("{}".utf8)
        )
        try validate(response: response, data: data, fallback: L10n.text("submissionError"))
        return try MatchQuizDecoding.decodeDetail(from: data)
    }

    @MainActor
    func updateQuiz(id: String, request: MatchQuizPatchRequest) async throws -> MatchQuizDetail {
        let body = try JSONEncoder().encode(request)
        let (data, response) = try await authorizedRequest(
            path: APIEndpoints.quizPatch(id),
            method: "PATCH",
            body: body
        )
        try validate(response: response, data: data, fallback: L10n.text("submissionError"))
        return try MatchQuizDecoding.decodeDetail(from: data)
    }

    @MainActor
    func publishQuiz(id: String) async throws -> MatchQuizDetail {
        try await updateQuiz(
            id: id,
            request: MatchQuizPatchRequest(status: "open")
        )
    }

    @MainActor
    func closeQuiz(id: String) async throws -> MatchQuizDetail {
        try await updateQuiz(
            id: id,
            request: MatchQuizPatchRequest(status: "closed")
        )
    }

    @MainActor
    func deleteQuiz(id: String) async throws {
        let (data, response) = try await authorizedRequest(
            path: APIEndpoints.deleteQuiz(id),
            method: "DELETE"
        )
        try validate(response: response, data: data, fallback: L10n.text("submissionError"))
    }

    @MainActor
    func submitQuiz(id: String, request: MatchQuizSubmitRequest) async throws -> MatchQuizSubmitResult {
        let body = try JSONEncoder().encode(request)
        let (data, response) = try await authorizedRequest(
            path: APIEndpoints.quizSubmit(id),
            method: "POST",
            body: body
        )
        try validate(response: response, data: data, fallback: L10n.text("submissionError"))
        return try MatchQuizDecoding.decodeSubmitResult(from: data)
    }

    @MainActor
    func fetchUserSubmission(quizId: String) async throws -> MatchQuizUserSubmission? {
        let (data, response) = try await authorizedRequest(
            path: APIEndpoints.quizUserSubmission(quizId),
            method: "GET"
        )
        if response.statusCode == 404 {
            return nil
        }
        try validate(response: response, data: data, fallback: L10n.matchesLoading)
        return try MatchQuizDecoding.decodeUserSubmission(from: data)
    }

    @MainActor
    func fetchLeaderboard(quizId: String) async throws -> MatchQuizLeaderboardResponse {
        let (data, response) = try await authorizedRequest(
            path: APIEndpoints.quizLeaderboard(quizId),
            method: "GET"
        )
        try validate(response: response, data: data, fallback: L10n.matchesLoading)
        return try MatchQuizDecoding.decodeLeaderboard(from: data)
    }

    @MainActor
    private func authorizedRequest(
        path: String,
        method: String,
        body: Data? = nil
    ) async throws -> (Data, HTTPURLResponse) {
        do {
            return try await AuthenticatedAPIClient.performRequest(
                client: client,
                authService: authService,
                path: path,
                method: method,
                body: body
            )
        } catch ServiceAuthError.unauthorized {
            throw QuizServiceError.unauthorized
        }
    }

    private func validate(response: HTTPURLResponse, data: Data, fallback: String) throws {
        guard HTTPResponseValidator.isSuccess(response) else {
            throw QuizServiceError.requestFailed(
                HTTPResponseValidator.localizedErrorMessage(from: data, fallback: fallback)
            )
        }
    }
}
