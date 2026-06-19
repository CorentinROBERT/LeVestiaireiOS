//
//  MatchListResponse.swift
//  LeVestaire
//
//  Created by Corentin Robert on 17/06/2026.
//

import Foundation

struct MatchListResponse: Decodable {
    let success: Bool
    let message: String?
    let error: String?
    let matches: [MatchItem]
    let pagination: PaginationInfo?

    var pageInfo: PaginationInfo? {
        pagination
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        success = try container.decodeIfPresent(Bool.self, forKey: .success) ?? true
        message = try container.decodeIfPresent(String.self, forKey: .message)
        error = try container.decodeIfPresent(String.self, forKey: .error)
        pagination = try container.decodeIfPresent(PaginationInfo.self, forKey: .pagination)

        if let array = try? container.decode([MatchItem].self, forKey: .data) {
            matches = array
        } else if let nested = try? container.decode(MatchListData.self, forKey: .data) {
            matches = nested.items ?? nested.matches ?? []
        } else {
            matches = try container.decodeIfPresent([MatchItem].self, forKey: .items) ?? []
        }
    }

    private enum CodingKeys: String, CodingKey {
        case success
        case message
        case error
        case data
        case items
        case pagination
    }
}

private struct MatchListData: Decodable {
    let items: [MatchItem]?
    let matches: [MatchItem]?
}

struct PaginationInfo: Decodable, Equatable {
    let page: Int
    let limit: Int
    let total: Int
    let totalPages: Int
    let hasNextPage: Bool

    init(page: Int, limit: Int, total: Int, totalPages: Int, hasNextPage: Bool) {
        self.page = page
        self.limit = limit
        self.total = total
        self.totalPages = totalPages
        self.hasNextPage = hasNextPage
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        page = try container.decodeIfPresent(Int.self, forKey: .page)
            ?? container.decodeIfPresent(Int.self, forKey: .currentPage)
            ?? 1
        limit = try container.decodeIfPresent(Int.self, forKey: .limit)
            ?? container.decodeIfPresent(Int.self, forKey: .itemsPerPage)
            ?? 20
        total = try container.decodeIfPresent(Int.self, forKey: .total)
            ?? container.decodeIfPresent(Int.self, forKey: .totalItems)
            ?? container.decodeIfPresent(Int.self, forKey: .count)
            ?? 0
        totalPages = try container.decodeIfPresent(Int.self, forKey: .totalPages) ?? 1

        if let explicit = try container.decodeIfPresent(Bool.self, forKey: .hasNextPage) {
            hasNextPage = explicit
        } else {
            hasNextPage = page < totalPages
        }
    }

    private enum CodingKeys: String, CodingKey {
        case page
        case currentPage
        case limit
        case itemsPerPage
        case total
        case totalItems
        case count
        case totalPages
        case hasNextPage
    }
}

struct MatchFilters: Equatable {
    var statuses: Set<MatchStatus> = []
    var teamIds: Set<String> = []
    var fromDate: Date?
    var toDate: Date?

    var activeFilterCount: Int {
        var count = 0
        if !statuses.isEmpty { count += 1 }
        if !teamIds.isEmpty { count += 1 }
        if fromDate != nil { count += 1 }
        if toDate != nil { count += 1 }
        return count
    }

    var hasActiveFilters: Bool {
        activeFilterCount > 0
    }

    func includes(_ item: MatchItem) -> Bool {
        if !statuses.isEmpty, !statuses.contains(item.status) {
            return false
        }

        if !teamIds.isEmpty {
            guard let teamId = item.teamId, teamIds.contains(teamId) else {
                return false
            }
        }

        if let fromDate {
            let startOfFromDate = Calendar.current.startOfDay(for: fromDate)
            if item.date < startOfFromDate {
                return false
            }
        }

        if let toDate {
            let startOfDayAfterToDate = Calendar.current.date(byAdding: .day, value: 1, to: Calendar.current.startOfDay(for: toDate)) ?? toDate
            if item.date >= startOfDayAfterToDate {
                return false
            }
        }

        return true
    }
}
