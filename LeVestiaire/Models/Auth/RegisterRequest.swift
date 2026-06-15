//
//  RegisterRequest.swift
//  LeVestaire
//
//  Created by Corentin Robert on 15/06/2026.
//

import Foundation

struct RegisterRequest: Encodable, Equatable {
    let email: String
    let password: String
    let firstName: String
    let lastName: String
    let birthdate: String?
    let language: String?

    init(
        email: String,
        password: String,
        firstName: String,
        lastName: String,
        birthDate: Date? = nil,
        language: String? = nil
    ) {
        self.email = email
        self.password = password
        self.firstName = firstName
        self.lastName = lastName

        if let birthDate {
            self.birthdate = Self.birthdateFormatter.string(from: birthDate)
        } else {
            self.birthdate = nil
        }

        self.language = language
    }

    private static let birthdateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }()
}
