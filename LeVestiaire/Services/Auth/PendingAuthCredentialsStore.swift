//
//  PendingAuthCredentialsStore.swift
//  LeVestaire
//
//  Created by Corentin Robert on 16/06/2026.
//

import Foundation

/// Stocke temporairement email + mot de passe pendant le flux inscription / vérification.
/// Mémoire uniquement — effacé après connexion ou déconnexion.
final class PendingAuthCredentialsStore {
    static let shared = PendingAuthCredentialsStore()

    private struct Credentials {
        let email: String
        let password: String
    }

    private var credentials: Credentials?

    func save(email: String, password: String) {
        let trimmedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedEmail.isEmpty, !password.isEmpty else { return }

        credentials = Credentials(email: trimmedEmail, password: password)
    }

    func load() -> (email: String, password: String)? {
        guard let credentials else { return nil }
        return (credentials.email, credentials.password)
    }

    func clear() {
        credentials = nil
    }
}
