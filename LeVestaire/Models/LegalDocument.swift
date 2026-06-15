//
//  LegalDocument.swift
//  LeVestaire
//
//  Created by Corentin Robert on 14/06/2026.
//

import Foundation

enum LegalDocument: String, CaseIterable, Identifiable {
    case termsOfUse
    case betaWarning
    case privacyPolicy

    private static let rawBaseURL = "https://raw.githubusercontent.com/CorentinROBERT/squadLockerLegal/main"
    private static let version = "V1.0.0"

    var id: String { rawValue }

    var title: String {
        switch self {
        case .termsOfUse:
            return "Conditions d'utilisation"
        case .betaWarning:
            return "Avertissement beta"
        case .privacyPolicy:
            return "Politique de confidentialité"
        }
    }

    private var folderName: String {
        switch self {
        case .termsOfUse:
            return "CGU"
        case .betaWarning:
            return "BetaDisclaimer"
        case .privacyPolicy:
            return "PrivacyPolicy"
        }
    }

    func rawURL(for language: AppLanguage) -> URL {
        let urlString = "\(Self.rawBaseURL)/\(folderName)/\(Self.version)/\(language.rawValue).md"
        return URL(string: urlString)!
    }
}
