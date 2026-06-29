//
//  LegalDocumentViewModel.swift
//  LeVestaire
//
//  Created by Corentin Robert on 14/06/2026.
//

import Combine
import Foundation

enum LegalDocumentError: LocalizedError {
    case invalidResponse
    case unreadableContent

    var errorDescription: String? {
        switch self {
        case .invalidResponse:
            return L10n.documentLoadFailed
        case .unreadableContent:
            return L10n.documentUnreadable
        }
    }
}

@MainActor
final class LegalDocumentViewModel: ObservableObject {
    @Published private(set) var markdown: String?
    @Published private(set) var isLoading = false
    @Published private(set) var errorMessage: String?

    let document: LegalDocument
    let language: AppLanguage

    private let contentFetcher: any RemoteContentFetching

    init(
        document: LegalDocument,
        language: AppLanguage,
        contentFetcher: any RemoteContentFetching = SharedRemoteContentFetcher()
    ) {
        self.document = document
        self.language = language
        self.contentFetcher = contentFetcher
    }

    func load() async {
        guard !isLoading else { return }

        isLoading = true
        errorMessage = nil
        markdown = nil

        defer { isLoading = false }

        do {
            markdown = try await fetchMarkdown()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func fetchMarkdown() async throws -> String {
        let url = document.rawURL(for: language)
        let (data, response) = try await contentFetcher.data(from: url)

        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw LegalDocumentError.invalidResponse
        }

        guard let markdown = String(data: data, encoding: .utf8) else {
            throw LegalDocumentError.unreadableContent
        }

        return markdown
    }
}
