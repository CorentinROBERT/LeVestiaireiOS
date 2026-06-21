//
//  MatchQuizModels.swift
//  LeVestaire
//

import Foundation

enum MatchQuizStatus: String, Equatable {
    case draft
    case open
    case closed
    case finished
    case unknown

    init(rawAPIValue: String?) {
        switch rawAPIValue?.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() {
        case "draft", "preparation", "preparing":
            self = .draft
        case "open", "opened":
            self = .open
        case "closed":
            self = .closed
        case "finished":
            self = .finished
        default:
            self = .unknown
        }
    }

    var isEditable: Bool {
        self == .draft
    }

    var isPlayable: Bool {
        self == .open
    }

    var showsLeaderboard: Bool {
        self == .closed || self == .finished
    }
}

struct MatchQuizSummary: Decodable, Identifiable, Equatable {
    let id: String
    let title: String?
    let status: String?

    var resolvedStatus: MatchQuizStatus {
        MatchQuizStatus(rawAPIValue: status)
    }

    var resolvedTitle: String {
        let trimmed = title?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        return trimmed.isEmpty ? L10n.text("quiz") : trimmed
    }

    var statusLabel: String {
        switch resolvedStatus {
        case .open:
            return L10n.text("quizOpened")
        case .closed:
            return L10n.text("quizClosed")
        case .finished:
            return L10n.text("quizFinished")
        case .draft:
            return L10n.text("quizInPreparation")
        case .unknown:
            return L10n.text("quizComingSoon")
        }
    }

    init(id: String, title: String?, status: String?) {
        self.id = id
        self.title = title
        self.status = status
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

struct MatchQuizQuestion: Identifiable, Equatable {
    let id: String
    let tempId: String?
    var text: String
    var correctAnswer: Bool?
    let type: String
    let textKey: String?
    var textRaw: String?
    let locale: String?
    let textParams: MatchQuizTextParams?
    let source: String

    var isSystemGenerated: Bool {
        source == "system"
    }

    var hasDefinedAnswer: Bool {
        correctAnswer != nil
    }

    init(
        id: String = UUID().uuidString,
        tempId: String? = nil,
        text: String = "",
        correctAnswer: Bool? = nil,
        type: String = "true_false",
        textKey: String? = nil,
        textRaw: String? = nil,
        locale: String? = nil,
        textParams: MatchQuizTextParams? = nil,
        source: String = "system"
    ) {
        self.id = id
        self.tempId = tempId
        self.text = text
        self.correctAnswer = correctAnswer
        self.type = type
        self.textKey = textKey
        self.textRaw = textRaw
        self.locale = locale
        self.textParams = textParams
        self.source = source
    }

    func draftQuestionPatch(locale: String) -> MatchQuizDraftQuestionPatch {
        let resolvedTextRaw: String? = {
            if isSystemGenerated { return textRaw }
            let candidate = textRaw ?? text
            let trimmed = candidate.trimmingCharacters(in: .whitespacesAndNewlines)
            return trimmed.isEmpty ? nil : trimmed
        }()

        return MatchQuizDraftQuestionPatch(
            type: type,
            textKey: textKey,
            textRaw: resolvedTextRaw,
            locale: locale,
            textParams: textParams,
            isTrue: correctAnswer,
            source: source
        )
    }
}

enum MatchQuizJSONValue: Equatable {
    case string(String)
    case int(Int)
    case double(Double)
    case bool(Bool)
}

struct MatchQuizTextParams: Equatable {
    let values: [String: MatchQuizJSONValue]

    init(values: [String: MatchQuizJSONValue] = [:]) {
        self.values = values
    }
}

extension MatchQuizTextParams: Codable {
    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let raw = try container.decode([String: MatchQuizJSONValue].self)
        values = raw
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(values)
    }
}

extension MatchQuizJSONValue: Codable {
    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let value = try? container.decode(Bool.self) {
            self = .bool(value)
        } else if let value = try? container.decode(Int.self) {
            self = .int(value)
        } else if let value = try? container.decode(Double.self) {
            self = .double(value)
        } else {
            self = .string(try container.decode(String.self))
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case .string(let value):
            try container.encode(value)
        case .int(let value):
            try container.encode(value)
        case .double(let value):
            try container.encode(value)
        case .bool(let value):
            try container.encode(value)
        }
    }
}

struct MatchQuizDraftQuestion: Decodable, Equatable {
    let id: String
    let type: String?
    let textKey: String?
    let textRaw: String?
    let locale: String?
    let textParams: MatchQuizTextParams?
    let source: String?
    let correctAnswer: Bool?

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decodeIfPresent(String.self, forKey: .mongoId)
            ?? container.decodeIfPresent(String.self, forKey: .id)
            ?? ""
        type = try container.decodeIfPresent(String.self, forKey: .type)
        textKey = try container.decodeIfPresent(String.self, forKey: .textKey)
        textRaw = try container.decodeIfPresent(String.self, forKey: .textRaw)
        locale = try container.decodeIfPresent(String.self, forKey: .locale)
        textParams = try container.decodeIfPresent(MatchQuizTextParams.self, forKey: .textParams)
        source = try container.decodeIfPresent(String.self, forKey: .source)
        correctAnswer = Self.decodeAnswer(from: container)
    }

    private enum CodingKeys: String, CodingKey {
        case mongoId = "_id"
        case id
        case type
        case textKey
        case textRaw
        case locale
        case textParams
        case source
        case correctAnswer
        case isTrue
        case answer
    }

    private static func decodeAnswer(from container: KeyedDecodingContainer<CodingKeys>) -> Bool? {
        if let value = try? container.decode(Bool.self, forKey: .correctAnswer) { return value }
        if let value = try? container.decode(Bool.self, forKey: .isTrue) { return value }
        if let value = try? container.decode(Bool.self, forKey: .answer) { return value }
        return nil
    }
}

struct MatchQuizDisplayQuestion: Decodable, Equatable {
    let tempId: String?
    let id: String?
    let type: String?
    let text: String
    let correctAnswer: Bool?

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        tempId = try container.decodeIfPresent(String.self, forKey: .tempId)
        id = try container.decodeIfPresent(String.self, forKey: .mongoId)
            ?? container.decodeIfPresent(String.self, forKey: .id)
        type = try container.decodeIfPresent(String.self, forKey: .type)
        text = try container.decodeIfPresent(String.self, forKey: .text)
            ?? container.decodeIfPresent(String.self, forKey: .statement)
            ?? ""
        if let value = try container.decodeIfPresent(Bool.self, forKey: .correctAnswer) {
            correctAnswer = value
        } else if let value = try container.decodeIfPresent(Bool.self, forKey: .isTrue) {
            correctAnswer = value
        } else if let value = try container.decodeIfPresent(Bool.self, forKey: .answer) {
            correctAnswer = value
        } else {
            correctAnswer = nil
        }
    }

    private enum CodingKeys: String, CodingKey {
        case tempId
        case mongoId = "_id"
        case id
        case type
        case text
        case statement
        case correctAnswer
        case isTrue
        case answer
    }
}

struct MatchQuizProgressStats: Decodable, Equatable {
    let participantCount: Int?
    let perfectScoreCount: Int?
    let completedCount: Int?
    let falseAnswersCount: Int?

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        participantCount = try container.decodeIfPresent(Int.self, forKey: .participantCount)
            ?? container.decodeIfPresent(Int.self, forKey: .participantsCount)
        perfectScoreCount = try container.decodeIfPresent(Int.self, forKey: .perfectScoreCount)
            ?? container.decodeIfPresent(Int.self, forKey: .perfectScoresCount)
        completedCount = try container.decodeIfPresent(Int.self, forKey: .completedCount)
            ?? container.decodeIfPresent(Int.self, forKey: .submissionsCount)
        falseAnswersCount = try container.decodeIfPresent(Int.self, forKey: .falseAnswersCount)
            ?? container.decodeIfPresent(Int.self, forKey: .falseCount)
    }

    private enum CodingKeys: String, CodingKey {
        case participantCount
        case participantsCount
        case perfectScoreCount
        case perfectScoresCount
        case completedCount
        case submissionsCount
        case falseAnswersCount
        case falseCount
    }
}

struct MatchQuizRecord: Decodable, Equatable {
    let id: String
    let matchId: String?
    let teamId: String?
    let title: String?
    let status: String?
    let playEligibility: String?
    let draftQuestions: [MatchQuizDraftQuestion]?
    let falseAnswersCount: Int?

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decodeIfPresent(String.self, forKey: .mongoId)
            ?? container.decodeIfPresent(String.self, forKey: .id)
            ?? ""
        matchId = try container.decodeIfPresent(String.self, forKey: .matchId)
        teamId = try container.decodeIfPresent(String.self, forKey: .teamId)
        title = try container.decodeIfPresent(String.self, forKey: .title)
            ?? container.decodeIfPresent(String.self, forKey: .name)
        status = try container.decodeIfPresent(String.self, forKey: .status)
        playEligibility = try container.decodeIfPresent(String.self, forKey: .playEligibility)
        draftQuestions = try container.decodeIfPresent([MatchQuizDraftQuestion].self, forKey: .draftQuestions)
        falseAnswersCount = try container.decodeIfPresent(Int.self, forKey: .falseAnswersCount)
            ?? container.decodeIfPresent(Int.self, forKey: .falseCount)
    }

    private enum CodingKeys: String, CodingKey {
        case mongoId = "_id"
        case id
        case matchId
        case teamId
        case title
        case name
        case status
        case playEligibility
        case draftQuestions
        case falseAnswersCount
        case falseCount
    }
}

struct MatchQuizDetailPayload: Decodable, Equatable {
    let quiz: MatchQuizRecord?
    let questions: [MatchQuizDisplayQuestion]?
    let eligibleUserIds: [String]?
    let progressStats: MatchQuizProgressStats?

    init(
        quiz: MatchQuizRecord?,
        questions: [MatchQuizDisplayQuestion]? = nil,
        eligibleUserIds: [String]? = nil,
        progressStats: MatchQuizProgressStats? = nil
    ) {
        self.quiz = quiz
        self.questions = questions
        self.eligibleUserIds = eligibleUserIds
        self.progressStats = progressStats
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        if let nestedQuiz = try container.decodeIfPresent(MatchQuizRecord.self, forKey: .quiz) {
            quiz = nestedQuiz
            questions = try container.decodeIfPresent([MatchQuizDisplayQuestion].self, forKey: .questions)
            eligibleUserIds = try container.decodeIfPresent([String].self, forKey: .eligibleUserIds)
            progressStats = try container.decodeIfPresent(MatchQuizProgressStats.self, forKey: .progressStats)
            return
        }

        quiz = try MatchQuizRecord(from: decoder)
        questions = try container.decodeIfPresent([MatchQuizDisplayQuestion].self, forKey: .questions)
        eligibleUserIds = try container.decodeIfPresent([String].self, forKey: .eligibleUserIds)
        progressStats = try container.decodeIfPresent(MatchQuizProgressStats.self, forKey: .progressStats)
    }

    private enum CodingKeys: String, CodingKey {
        case quiz
        case questions
        case eligibleUserIds
        case progressStats
    }
}

struct MatchQuizDetail: Identifiable, Equatable {
    let id: String
    let matchId: String?
    let teamId: String?
    let title: String?
    let status: String?
    let playEligibility: String?
    let questions: [MatchQuizQuestion]
    let eligibleUserIds: [String]
    let falseAnswersCount: Int?
    let participantCount: Int?
    let completedCount: Int?

    var resolvedStatus: MatchQuizStatus {
        MatchQuizStatus(rawAPIValue: status)
    }

    var resolvedTitle: String {
        let trimmed = title?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        return trimmed.isEmpty ? L10n.text("quiz") : trimmed
    }

    var resolvedFalseAnswersCount: Int {
        if let falseAnswersCount, falseAnswersCount > 0 {
            return falseAnswersCount
        }
        return questions.filter { $0.correctAnswer == false }.count
    }

    var sortedQuestions: [MatchQuizQuestion] {
        questions
    }

    var isValidForPublish: Bool {
        questions.count == 10
            && questions.allSatisfy(\.hasDefinedAnswer)
            && resolvedFalseAnswersCount >= 1
    }

    init(
        id: String,
        matchId: String? = nil,
        teamId: String? = nil,
        title: String? = nil,
        status: String? = nil,
        playEligibility: String? = nil,
        questions: [MatchQuizQuestion] = [],
        eligibleUserIds: [String] = [],
        falseAnswersCount: Int? = nil,
        participantCount: Int? = nil,
        completedCount: Int? = nil
    ) {
        self.id = id
        self.matchId = matchId
        self.teamId = teamId
        self.title = title
        self.status = status
        self.playEligibility = playEligibility
        self.questions = questions
        self.eligibleUserIds = eligibleUserIds
        self.falseAnswersCount = falseAnswersCount
        self.participantCount = participantCount
        self.completedCount = completedCount
    }

    init(payload: MatchQuizDetailPayload) {
        let quiz = payload.quiz
        id = quiz?.id ?? ""
        matchId = quiz?.matchId
        teamId = quiz?.teamId
        title = quiz?.title
        status = quiz?.status
        playEligibility = quiz?.playEligibility
        eligibleUserIds = payload.eligibleUserIds ?? []
        questions = Self.mergeQuestions(
            draftQuestions: quiz?.draftQuestions ?? [],
            displayQuestions: payload.questions ?? []
        )
        falseAnswersCount = payload.progressStats?.falseAnswersCount ?? quiz?.falseAnswersCount
        participantCount = payload.progressStats?.participantCount
        completedCount = payload.progressStats?.perfectScoreCount ?? payload.progressStats?.completedCount
    }

    private static func mergeQuestions(
        draftQuestions: [MatchQuizDraftQuestion],
        displayQuestions: [MatchQuizDisplayQuestion]
    ) -> [MatchQuizQuestion] {
        if !displayQuestions.isEmpty {
            return displayQuestions.enumerated().map { index, display in
                let draft = index < draftQuestions.count ? draftQuestions[index] : nil
                let resolvedId = draft?.id
                    ?? display.id
                    ?? display.tempId
                    ?? UUID().uuidString
                return MatchQuizQuestion(
                    id: resolvedId,
                    tempId: display.tempId,
                    text: display.text,
                    correctAnswer: draft?.correctAnswer ?? display.correctAnswer,
                    type: draft?.type ?? display.type ?? "true_false",
                    textKey: draft?.textKey,
                    textRaw: draft?.textRaw,
                    locale: draft?.locale,
                    textParams: draft?.textParams,
                    source: draft?.source ?? "system"
                )
            }
        }

        if !draftQuestions.isEmpty {
            return draftQuestions.map {
                MatchQuizQuestion(
                    id: $0.id,
                    text: $0.textRaw ?? $0.textKey ?? "",
                    correctAnswer: $0.correctAnswer,
                    type: $0.type ?? "true_false",
                    textKey: $0.textKey,
                    textRaw: $0.textRaw,
                    locale: $0.locale,
                    textParams: $0.textParams,
                    source: $0.source ?? "system"
                )
            }
        }

        return []
    }
}

struct MatchQuizAnswerDraft: Equatable {
    let questionId: String
    let tempId: String?
    var answer: Bool?

    init(questionId: String, tempId: String? = nil, answer: Bool? = nil) {
        self.questionId = questionId
        self.tempId = tempId
        self.answer = answer
    }
}

struct MatchQuizAnswerSubmission: Codable, Equatable {
    let questionId: String
    let tempId: String?
    let answer: Bool

    init(questionId: String, tempId: String? = nil, answer: Bool) {
        self.questionId = questionId
        self.tempId = tempId
        self.answer = answer
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        questionId = try container.decodeIfPresent(String.self, forKey: .questionId)
            ?? container.decodeIfPresent(String.self, forKey: .mongoId)
            ?? container.decodeIfPresent(String.self, forKey: .id)
            ?? ""
        tempId = try container.decodeIfPresent(String.self, forKey: .tempId)
        answer = try container.decodeIfPresent(Bool.self, forKey: .answer)
            ?? container.decodeIfPresent(Bool.self, forKey: .isTrue)
            ?? false
    }

    private enum CodingKeys: String, CodingKey {
        case questionId
        case mongoId = "_id"
        case id
        case tempId
        case answer
        case isTrue
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(questionId, forKey: .questionId)
        try container.encodeIfPresent(tempId, forKey: .tempId)
        try container.encode(answer, forKey: .answer)
        try container.encode(answer, forKey: .isTrue)
    }
}

struct MatchQuizSubmitRequest: Encodable {
    let answers: [MatchQuizAnswerSubmission]
}

struct MatchQuizSubmitResult: Decodable, Equatable {
    let isComplete: Bool
    let falseFound: Int
    let falseAnswersCount: Int
    let attemptCount: Int
    let remainingFalseAnswers: Int?

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        isComplete = try container.decodeIfPresent(Bool.self, forKey: .isComplete)
            ?? container.decodeIfPresent(Bool.self, forKey: .complete)
            ?? container.decodeIfPresent(Bool.self, forKey: .success)
            ?? false
        falseFound = try container.decodeIfPresent(Int.self, forKey: .falseFound)
            ?? container.decodeIfPresent(Int.self, forKey: .falseAnswersFound)
            ?? 0
        falseAnswersCount = try container.decodeIfPresent(Int.self, forKey: .falseAnswersCount)
            ?? container.decodeIfPresent(Int.self, forKey: .falseCount)
            ?? 0
        attemptCount = try container.decodeIfPresent(Int.self, forKey: .attemptCount)
            ?? container.decodeIfPresent(Int.self, forKey: .attempts)
            ?? 1
        remainingFalseAnswers = try container.decodeIfPresent(Int.self, forKey: .remainingFalseAnswers)
    }

    private enum CodingKeys: String, CodingKey {
        case isComplete
        case complete
        case success
        case falseFound
        case falseAnswersFound
        case falseAnswersCount
        case falseCount
        case attemptCount
        case attempts
        case remainingFalseAnswers
    }
}

struct MatchQuizUserSubmission: Decodable, Equatable {
    let attemptCount: Int
    let isComplete: Bool
    let falseFound: Int?
    let falseAnswersCount: Int?
    let answers: [MatchQuizAnswerSubmission]?

    var isPerfect: Bool { isComplete }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        attemptCount = try container.decodeIfPresent(Int.self, forKey: .attemptCount)
            ?? container.decodeIfPresent(Int.self, forKey: .attempts)
            ?? 0
        isComplete = try container.decodeIfPresent(Bool.self, forKey: .isComplete)
            ?? container.decodeIfPresent(Bool.self, forKey: .complete)
            ?? false
        falseFound = try container.decodeIfPresent(Int.self, forKey: .falseFound)
        falseAnswersCount = try container.decodeIfPresent(Int.self, forKey: .falseAnswersCount)
        answers = try container.decodeIfPresent([MatchQuizAnswerSubmission].self, forKey: .answers)
    }

    private enum CodingKeys: String, CodingKey {
        case attemptCount
        case attempts
        case isComplete
        case complete
        case falseFound
        case falseAnswersCount
        case answers
    }
}

struct MatchQuizLeaderboardCounts: Decodable, Equatable {
    let totalQuestions: Int?
    let participants: Int?
    let eligible: Int?

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        totalQuestions = try container.decodeIfPresent(Int.self, forKey: .totalQuestions)
        participants = try container.decodeIfPresent(Int.self, forKey: .participants)
            ?? container.decodeIfPresent(Int.self, forKey: .participantCount)
        eligible = try container.decodeIfPresent(Int.self, forKey: .eligible)
            ?? container.decodeIfPresent(Int.self, forKey: .eligibleCount)
    }

    private enum CodingKeys: String, CodingKey {
        case totalQuestions
        case participants
        case participantCount
        case eligible
        case eligibleCount
    }
}

struct MatchQuizLeaderboardSummary: Decodable, Equatable {
    let id: String
    let title: String?
    let status: String?

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decodeIfPresent(String.self, forKey: .mongoId)
            ?? container.decodeIfPresent(String.self, forKey: .id)
            ?? ""
        title = try container.decodeIfPresent(String.self, forKey: .title)
        status = try container.decodeIfPresent(String.self, forKey: .status)
    }

    private enum CodingKeys: String, CodingKey {
        case mongoId = "_id"
        case id
        case title
        case status
    }
}

struct MatchQuizLeaderboardPayload: Decodable, Equatable {
    let quiz: MatchQuizLeaderboardSummary?
    let counts: MatchQuizLeaderboardCounts?
    let leaderboard: [MatchQuizLeaderboardEntry]?
    let entries: [MatchQuizLeaderboardEntry]?

    var resolvedEntries: [MatchQuizLeaderboardEntry] {
        leaderboard ?? entries ?? []
    }
}

struct MatchQuizLeaderboardResponse: Equatable {
    let quiz: MatchQuizLeaderboardSummary?
    let counts: MatchQuizLeaderboardCounts?
    let entries: [MatchQuizLeaderboardEntry]

    init(
        quiz: MatchQuizLeaderboardSummary? = nil,
        counts: MatchQuizLeaderboardCounts? = nil,
        entries: [MatchQuizLeaderboardEntry] = []
    ) {
        self.quiz = quiz
        self.counts = counts
        self.entries = entries
    }

    init(payload: MatchQuizLeaderboardPayload) {
        quiz = payload.quiz
        counts = payload.counts
        entries = payload.resolvedEntries
    }
}

struct MatchQuizLeaderboardEntry: Identifiable, Decodable, Equatable {
    let id: String
    let displayName: String
    let attemptCount: Int
    let rank: Int?
    let isComplete: Bool

    init(
        id: String = UUID().uuidString,
        displayName: String,
        attemptCount: Int,
        rank: Int? = nil,
        isComplete: Bool = true
    ) {
        self.id = id
        self.displayName = displayName
        self.attemptCount = attemptCount
        self.rank = rank
        self.isComplete = isComplete
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let userId = try container.decodeIfPresent(String.self, forKey: .userId)
        id = try container.decodeIfPresent(String.self, forKey: .mongoId)
            ?? container.decodeIfPresent(String.self, forKey: .id)
            ?? userId
            ?? UUID().uuidString
        displayName = try container.decodeIfPresent(String.self, forKey: .displayName)
            ?? container.decodeIfPresent(String.self, forKey: .name)
            ?? container.decodeIfPresent(String.self, forKey: .username)
            ?? L10n.text("unknownName")
        attemptCount = try container.decodeIfPresent(Int.self, forKey: .attemptCount)
            ?? container.decodeIfPresent(Int.self, forKey: .attempts)
            ?? 0
        rank = try container.decodeIfPresent(Int.self, forKey: .rank)
        isComplete = try container.decodeIfPresent(Bool.self, forKey: .isComplete)
            ?? container.decodeIfPresent(Bool.self, forKey: .complete)
            ?? true
    }

    private enum CodingKeys: String, CodingKey {
        case mongoId = "_id"
        case id
        case userId
        case displayName
        case name
        case username
        case attemptCount
        case attempts
        case rank
        case isComplete
        case complete
    }
}

struct MatchQuizDraftQuestionPatch: Encodable {
    let type: String
    let textKey: String?
    let textRaw: String?
    let locale: String?
    let textParams: MatchQuizTextParams?
    let isTrue: Bool?
    let source: String

    private enum CodingKeys: String, CodingKey {
        case type
        case textKey
        case textRaw
        case locale
        case textParams
        case isTrue
        case source
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(type, forKey: .type)
        if let textKey, !textKey.isEmpty {
            try container.encode(textKey, forKey: .textKey)
        }
        if let textRaw, !textRaw.isEmpty {
            try container.encode(textRaw, forKey: .textRaw)
        }
        try container.encodeIfPresent(locale, forKey: .locale)
        try container.encodeIfPresent(textParams, forKey: .textParams)
        try container.encodeIfPresent(isTrue, forKey: .isTrue)
        try container.encode(source, forKey: .source)
    }
}

struct MatchQuizPatchRequest: Encodable {
    let title: String?
    let status: String?
    let draftQuestions: [MatchQuizDraftQuestionPatch]?

    init(
        title: String? = nil,
        status: String? = nil,
        draftQuestions: [MatchQuizDraftQuestionPatch]? = nil
    ) {
        self.title = title
        self.status = status
        self.draftQuestions = draftQuestions
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

    static func decodeDetail(from data: Data) throws -> MatchQuizDetail {
        if let payload = try? APIResponseDecoder.decodePayload(MatchQuizDetailPayload.self, from: data) {
            let detail = MatchQuizDetail(payload: payload)
            if !detail.id.isEmpty {
                return detail
            }
        }

        if let quiz = try? APIResponseDecoder.decodePayload(MatchQuizRecord.self, from: data),
           !quiz.id.isEmpty {
            return MatchQuizDetail(payload: MatchQuizDetailPayload(quiz: quiz))
        }

        if let payload = try? JSONDecoder().decode(MatchQuizDetailPayload.self, from: data),
           payload.quiz?.id.isEmpty == false {
            return MatchQuizDetail(payload: payload)
        }

        if let quiz = try? JSONDecoder().decode(MatchQuizRecord.self, from: data),
           !quiz.id.isEmpty {
            return MatchQuizDetail(payload: MatchQuizDetailPayload(quiz: quiz))
        }

        throw DecodingError.dataCorrupted(
            DecodingError.Context(
                codingPath: [],
                debugDescription: L10n.decodeApiResponseFailed("MatchQuizDetail")
            )
        )
    }

    static func decodeSubmitResult(from data: Data) throws -> MatchQuizSubmitResult {
        if let result = try? APIResponseDecoder.decodePayload(MatchQuizSubmitResult.self, from: data) {
            return result
        }
        return try APIResponseDecoder.decode(MatchQuizSubmitResult.self, from: data)
    }

    static func decodeUserSubmission(from data: Data) throws -> MatchQuizUserSubmission? {
        if let submission = try? APIResponseDecoder.decodePayload(MatchQuizUserSubmission.self, from: data) {
            return submission
        }
        if let submission = try? APIResponseDecoder.decode(MatchQuizUserSubmission.self, from: data) {
            return submission
        }
        return nil
    }

    static func decodeLeaderboard(from data: Data) throws -> MatchQuizLeaderboardResponse {
        if let payload = try? APIResponseDecoder.decodePayload(MatchQuizLeaderboardPayload.self, from: data) {
            return MatchQuizLeaderboardResponse(payload: payload)
        }

        if let payload = try? JSONDecoder().decode(MatchQuizLeaderboardPayload.self, from: data) {
            return MatchQuizLeaderboardResponse(payload: payload)
        }

        if let entries = try? APIResponseDecoder.decodePayload([MatchQuizLeaderboardEntry].self, from: data) {
            return MatchQuizLeaderboardResponse(entries: entries)
        }

        if let entries = try? APIResponseDecoder.decode([MatchQuizLeaderboardEntry].self, from: data) {
            return MatchQuizLeaderboardResponse(entries: entries)
        }

        return MatchQuizLeaderboardResponse()
    }
}

#if DEBUG
extension MatchQuizDetail {
    static var preview: MatchQuizDetail {
        let json = """
        {
          "quiz": {
            "_id": "quiz-preview",
            "title": "Quiz du match",
            "status": "open",
            "falseAnswersCount": 4,
            "draftQuestions": [
              {"_id": "q1", "type": "true_false", "textKey": "quiz.fact_001", "textParams": {}, "isTrue": true, "source": "system"},
              {"_id": "q2", "type": "true_false", "textKey": "quiz.fact_002", "textParams": {}, "isTrue": false, "source": "system"},
              {"_id": "q3", "type": "true_false", "textKey": "quiz.fact_003", "textParams": {}, "isTrue": true, "source": "system"},
              {"_id": "q4", "type": "true_false", "textKey": "quiz.fact_004", "textParams": {}, "isTrue": false, "source": "system"},
              {"_id": "q5", "type": "true_false", "textKey": "quiz.fact_005", "textParams": {}, "isTrue": false, "source": "system"},
              {"_id": "q6", "type": "true_false", "textKey": "quiz.fact_006", "textParams": {}, "isTrue": true, "source": "system"},
              {"_id": "q7", "type": "true_false", "textKey": "quiz.fact_007", "textParams": {}, "isTrue": true, "source": "system"},
              {"_id": "q8", "type": "true_false", "textKey": "quiz.fact_008", "textParams": {}, "isTrue": false, "source": "system"},
              {"_id": "q9", "type": "true_false", "textKey": "quiz.fact_009", "textParams": {}, "isTrue": true, "source": "system"},
              {"_id": "q10", "type": "true_false", "textKey": "quiz.fact_010", "textParams": {}, "isTrue": true, "source": "system"}
            ]
          },
          "eligibleUserIds": ["user-eligible"],
          "questions": [
            {"tempId": "draft-0", "text": "Le match s'est terminé sur une victoire."},
            {"tempId": "draft-1", "text": "Il y a eu un carton rouge."},
            {"tempId": "draft-2", "text": "L'équipe a marqué en première mi-temps."},
            {"tempId": "draft-3", "text": "Le gardien a été remplacé."},
            {"tempId": "draft-4", "text": "Un penalty a été accordé."},
            {"tempId": "draft-5", "text": "Le score final était serré."},
            {"tempId": "draft-6", "text": "Il y a eu 3 remplacements."},
            {"tempId": "draft-7", "text": "Un joueur a marqué un triplé."},
            {"tempId": "draft-8", "text": "Le match s'est joué à domicile."},
            {"tempId": "draft-9", "text": "Aucun carton jaune n'a été distribué."}
          ],
          "progressStats": {
            "falseAnswersCount": 4,
            "participantCount": 8,
            "perfectScoreCount": 2
          }
        }
        """
        let payload = try! JSONDecoder().decode(MatchQuizDetailPayload.self, from: Data(json.utf8))
        return MatchQuizDetail(payload: payload)
    }
}
#endif
