//
//  LegalDocumentViewModelTests.swift
//  LeVestiaireTests
//

import Foundation
import Testing
@testable import LeVestiaire

@MainActor
struct LegalDocumentViewModelTests {
  @Test
  func load_setsMarkdownOnSuccess() async {
    let fetcher = MockRemoteContentFetcher()
    fetcher.dataHandler = { url in
      let response = HTTPURLResponse(
        url: url,
        statusCode: 200,
        httpVersion: nil,
        headerFields: nil
      )!
      return (Data("# Terms".utf8), response)
    }
    let viewModel = LegalDocumentViewModel(
      document: .termsOfUse,
      language: .french,
      contentFetcher: fetcher
    )

    await viewModel.load()

    #expect(viewModel.markdown == "# Terms")
    #expect(viewModel.errorMessage == nil)
    #expect(viewModel.isLoading == false)
  }

  @Test
  func load_setsErrorOnInvalidResponse() async {
    let fetcher = MockRemoteContentFetcher()
    fetcher.dataHandler = { url in
      let response = HTTPURLResponse(
        url: url,
        statusCode: 500,
        httpVersion: nil,
        headerFields: nil
      )!
      return (Data(), response)
    }
    let viewModel = LegalDocumentViewModel(
      document: .privacyPolicy,
      language: .english,
      contentFetcher: fetcher
    )

    await viewModel.load()

    #expect(viewModel.markdown == nil)
    #expect(viewModel.errorMessage != nil)
  }
}
