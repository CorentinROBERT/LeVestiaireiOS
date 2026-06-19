//
//  EditMatchViewModel.swift
//  LeVestaire
//

import Combine
import Foundation

@MainActor
final class EditMatchViewModel: ObservableObject {
    @Published var opponentTeam = ""
    @Published var location = ""
    @Published var matchDate = Date()
    @Published var includesTime = false
    @Published var matchTime = Date()

    @Published private(set) var isSubmitting = false
    @Published var errorMessage: String?

    private let matchId: String
    private let matchService: MatchService

    var canSubmit: Bool {
        !isSubmitting
            && !opponentTeam.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            && !location.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            && !isDateTooFarInFuture
    }

    private var isDateTooFarInFuture: Bool {
        guard let maxDate = Calendar.current.date(byAdding: .year, value: 1, to: Date()) else {
            return false
        }
        return matchDate > maxDate
    }

    init(match: MatchDetail, matchService: MatchService) {
        self.matchId = match.id
        self.matchService = matchService
        opponentTeam = match.opponentTeam ?? ""
        location = match.location ?? ""
        matchDate = match.date

        if let startTime = match.startTime {
            includesTime = true
            matchTime = Self.date(fromTimeString: startTime) ?? match.date
        }
    }

    convenience init(match: MatchDetail) {
        self.init(match: match, matchService: MatchService.shared)
    }

    func saveChanges() async -> MatchDetail? {
        guard canSubmit else { return nil }

        isSubmitting = true
        errorMessage = nil
        defer { isSubmitting = false }

        let trimmedOpponent = opponentTeam.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedLocation = location.trimmingCharacters(in: .whitespacesAndNewlines)

        do {
            return try await matchService.updateMatch(
                id: matchId,
                request: UpdateMatchRequest(
                    opponentTeam: trimmedOpponent,
                    location: trimmedLocation,
                    date: MatchService.apiDateString(from: matchDate),
                    title: defaultTitle(opponent: trimmedOpponent),
                    description: nil,
                    time: includesTime
                        ? MatchService.apiTimeString(from: matchTime)
                        : MatchService.defaultMatchTime,
                    sendsTime: true
                )
            )
        } catch {
            errorMessage = error.localizedDescription
            return nil
        }
    }

    private func defaultTitle(opponent: String) -> String {
        "\(L10n.vs) \(opponent)"
    }

    private static func date(fromTimeString value: String) -> Date? {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "HH:mm"
        return formatter.date(from: value)
    }
}
