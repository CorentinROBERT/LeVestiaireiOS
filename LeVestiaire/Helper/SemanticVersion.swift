//
//  SemanticVersion.swift
//  LeVestaire
//

import Foundation

enum SemanticVersion {
    static func compare(_ lhs: String, _ rhs: String) -> ComparisonResult {
        let left = components(from: lhs)
        let right = components(from: rhs)
        let maxCount = max(left.count, right.count)

        for index in 0..<maxCount {
            let leftValue = index < left.count ? left[index] : 0
            let rightValue = index < right.count ? right[index] : 0
            if leftValue < rightValue { return .orderedAscending }
            if leftValue > rightValue { return .orderedDescending }
        }

        return .orderedSame
    }

    static func isValid(_ value: String) -> Bool {
        !components(from: value).isEmpty
    }

    private static func components(from value: String) -> [Int] {
        value
            .split(separator: ".", omittingEmptySubsequences: false)
            .prefix(3)
            .compactMap { Int($0) }
    }
}
