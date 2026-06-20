//
//  MatchQuizModels.swift
//  LeVestaire
//

import Foundation

struct MatchQuizSummary: Decodable, Identifiable, Equatable {
    let id: String
    let title: String?
    let status: String?

    var resolvedTitle: String {
        let trimmed = title?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        return trimmed.isEmpty ? L10n.text("quiz") : trimmed
    }

    var statusLabel: String {
        switch status?.lowercased() {
        case "open", "opened":
            return L10n.text("quizOpened")
        case "closed":
            return L10n.text("quizClosed")
        case "finished":
            return L10n.text("quizFinished")
        case "draft", "preparation", "preparing":
            return L10n.text("quizInPreparation")
        default:
            return L10n.text("quizComingSoon")
        }
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decodeIfPresent(String.self, forKey: .mongoId)
            ?? container.decodeIfPresent(String.self, forKey: .id)
            ?? ""
        title = try container.decodeIfPresent(String.self, forKey: .title)
            ?? container.decodeIfPresent(String.self, forKey: .name)
        status = try container.decodeIfPresent(String.self, forKey: .status)
    }

    private enum CodingKeys: String, CodingKey {
        case mongoId = "_id"
        case id
        case title
        case name
        case status
    }
}

enum MatchQuizDecoding {
    private struct QuizListPayload: Decodable {
        let quizzes: [MatchQuizSummary]?
        let items: [MatchQuizSummary]?
    }

    static func decodeList(from data: Data) throws -> [MatchQuizSummary] {
        if let quizzes = try? APIResponseDecoder.decodePayload([MatchQuizSummary].self, from: data) {
            return quizzes.filter { !$0.id.isEmpty }
        }
        if let quizzes = try? APIResponseDecoder.decode([MatchQuizSummary].self, from: data) {
            return quizzes.filter { !$0.id.isEmpty }
        }
        if let payload = try? APIResponseDecoder.decodePayload(QuizListPayload.self, from: data) {
            return (payload.quizzes ?? payload.items ?? []).filter { !$0.id.isEmpty }
        }
        if let payload = try? JSONDecoder().decode(QuizListPayload.self, from: data) {
            return (payload.quizzes ?? payload.items ?? []).filter { !$0.id.isEmpty }
        }
        return []
    }
}
