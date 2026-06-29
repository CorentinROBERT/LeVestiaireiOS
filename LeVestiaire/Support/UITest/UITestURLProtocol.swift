//
//  UITestURLProtocol.swift
//  LeVestaire
//

import Foundation

final class UITestURLProtocol: URLProtocol {
    override class func canInit(with request: URLRequest) -> Bool {
        guard UITestLaunchArgument.usesNetworkStub,
              let url = request.url else {
            return false
        }
        return url.path.contains("/api/")
    }

    override class func canonicalRequest(for request: URLRequest) -> URLRequest {
        request
    }

    override func startLoading() {
        guard let client else { return }

        var normalizedRequest = request
        if normalizedRequest.httpBody == nil,
           let stream = normalizedRequest.httpBodyStream {
            normalizedRequest.httpBody = Data(reading: stream)
        }

        let fixture = UITestFixtureResponses.response(for: normalizedRequest)
        let url = request.url ?? URL(string: "https://ui-test.local/api")!
        let response = HTTPURLResponse(
            url: url,
            statusCode: fixture.statusCode,
            httpVersion: nil,
            headerFields: ["Content-Type": "application/json"]
        )!

        client.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
        client.urlProtocol(self, didLoad: fixture.data)
        client.urlProtocolDidFinishLoading(self)
    }

    override func stopLoading() {}
}

private extension Data {
    init(reading stream: InputStream) {
        self.init()
        stream.open()
        defer { stream.close() }

        let bufferSize = 16_384
        let buffer = UnsafeMutablePointer<UInt8>.allocate(capacity: bufferSize)
        defer { buffer.deallocate() }

        while stream.hasBytesAvailable {
            let read = stream.read(buffer, maxLength: bufferSize)
            guard read > 0 else { break }
            append(buffer, count: read)
        }
    }
}
