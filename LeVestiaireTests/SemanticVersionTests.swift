//
//  SemanticVersionTests.swift
//  LeVestiaireTests
//

import Foundation
import Testing
@testable import LeVestiaire

struct SemanticVersionTests {

    @Test(arguments: [
        ("1.2.3", "1.2.10", ComparisonResult.orderedAscending),
        ("2.0", "1.9.9", ComparisonResult.orderedDescending),
        ("1.0.0", "1.0.0", ComparisonResult.orderedSame),
        ("1.2", "1.2.0", ComparisonResult.orderedSame),
        ("1.10.0", "1.9.0", ComparisonResult.orderedDescending),
    ])
    func compare(lhs: String, rhs: String, expected: ComparisonResult) {
        #expect(SemanticVersion.compare(lhs, rhs) == expected)
    }

    @Test(arguments: [
        "1.0",
        "1.0.0",
        "12.34.56",
    ])
    func isValid_acceptsNumericVersions(_ value: String) {
        #expect(SemanticVersion.isValid(value))
    }

    @Test(arguments: [
        "",
        "abc",
    ])
    func isValid_rejectsInvalidVersions(_ value: String) {
        #expect(!SemanticVersion.isValid(value))
    }

    @Test
    func isValid_acceptsPartialNumericSegments() {
        // Seuls les segments numériques sont pris en compte (ex. "beta" ignoré).
        #expect(SemanticVersion.isValid("1.beta.0"))
    }
}
