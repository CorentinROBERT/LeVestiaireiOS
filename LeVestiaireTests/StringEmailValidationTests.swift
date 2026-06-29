//
//  StringEmailValidationTests.swift
//  LeVestiaireTests
//

import Testing
@testable import LeVestiaire

struct StringEmailValidationTests {

    @Test(arguments: [
        "user@example.com",
        "test.user+tag@domain.co.uk",
        "A.B_C%+@mail.io",
    ])
    func isValidEmail_acceptsValidAddresses(_ email: String) {
        #expect(email.isValidEmail)
    }

    @Test(arguments: [
        "",
        "not-an-email",
        "missing-at-sign.com",
        "@no-local-part.com",
        "spaces in@mail.com",
        "user@",
        "user@domain",
    ])
    func isValidEmail_rejectsInvalidAddresses(_ email: String) {
        #expect(!email.isValidEmail)
    }

    @Test(arguments: [
        ("  hello@world.com  ", "hello@world.com"),
        ("no-trim-needed", "no-trim-needed"),
    ])
    func trimmed_removesSurroundingWhitespace(input: String, expected: String) {
        #expect(input.trimmed == expected)
    }
}
