//
//  LegalDocumentSheet.swift
//  LeVestaire
//
//  Created by Corentin Robert on 14/06/2026.
//

import SwiftUI

struct LegalDocumentSheet: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel: LegalDocumentViewModel

    init(document: LegalDocument, language: AppLanguage) {
        _viewModel = StateObject(
            wrappedValue: LegalDocumentViewModel(document: document, language: language)
        )
    }

    var body: some View {
        NavigationStack {
            ZStack {
                AppPalette.Neutral.background
                    .ignoresSafeArea()

                Group {
                    if viewModel.isLoading {
                        ProgressView("Chargement du document…")
                            .tint(AppPalette.Primary.main)
                    } else if let errorMessage = viewModel.errorMessage {
                        errorView(message: errorMessage)
                    } else if let markdown = viewModel.markdown {
                        ScrollView {
                            MarkdownContentView(markdown: markdown)
                                .padding(24)
                                .textSelection(.enabled)
                        }
                    }
                }
            }
            .navigationTitle(viewModel.document.title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Fermer") {
                        dismiss()
                    }
                }
            }
            .task {
                await viewModel.load()
            }
        }
        .presentationDragIndicator(.visible)
    }

    private func errorView(message: String) -> some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle")
                .font(.largeTitle)
                .foregroundStyle(AppPalette.Secondary.coral)

            Text(message)
                .font(.subheadline)
                .foregroundStyle(AppPalette.Neutral.textSecondary)
                .multilineTextAlignment(.center)

            Button("Réessayer") {
                Task {
                    await viewModel.load()
                }
            }
            .buttonStyle(.borderedProminent)
            .tint(AppPalette.Primary.main)
        }
        .padding(32)
    }
}

#Preview {
    LegalDocumentSheet(document: .termsOfUse, language: .french)
}
