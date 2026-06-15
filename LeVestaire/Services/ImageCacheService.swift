//
//  ImageCacheService.swift
//  LeVestaire
//
//  Created by Corentin Robert on 12/06/2026.
//

import CryptoKit
import Foundation
import UIKit

enum ImageCacheError: Error {
    case invalidImageData
}

actor ImageCacheService {
    static let shared = ImageCacheService()

    private let memoryCache = NSCache<NSURL, UIImage>()
    private var inFlightTasks: [URL: Task<UIImage, Error>] = [:]

    private let session: URLSession
    private let diskCacheDirectory: URL

    private init() {
        memoryCache.countLimit = 100
        memoryCache.totalCostLimit = 50 * 1024 * 1024

        let cache = URLCache(
            memoryCapacity: 50 * 1024 * 1024,
            diskCapacity: 200 * 1024 * 1024,
            diskPath: "LeVestaireURLCache"
        )

        let configuration = URLSessionConfiguration.default
        configuration.urlCache = cache
        configuration.requestCachePolicy = .returnCacheDataElseLoad
        session = URLSession(configuration: configuration)

        let cachesDirectory = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first!
        diskCacheDirectory = cachesDirectory.appendingPathComponent("RemoteImages", isDirectory: true)

        try? FileManager.default.createDirectory(at: diskCacheDirectory, withIntermediateDirectories: true)
    }

    func image(for url: URL) async throws -> UIImage {
        let cacheKey = url as NSURL

        if let cached = memoryCache.object(forKey: cacheKey) {
            return cached
        }

        if let diskImage = loadFromDisk(url: url) {
            memoryCache.setObject(diskImage, forKey: cacheKey, cost: diskImage.pngData()?.count ?? 0)
            return diskImage
        }

        if let existingTask = inFlightTasks[url] {
            return try await existingTask.value
        }

        let task = Task<UIImage, Error> {
            let request = URLRequest(url: url, cachePolicy: .returnCacheDataElseLoad)
            let (data, _) = try await session.data(for: request)

            guard let image = UIImage(data: data) else {
                throw ImageCacheError.invalidImageData
            }

            memoryCache.setObject(image, forKey: cacheKey, cost: data.count)
            saveToDisk(data: data, url: url)
            return image
        }

        inFlightTasks[url] = task

        defer { inFlightTasks[url] = nil }

        return try await task.value
    }

    private func diskCacheURL(for url: URL) -> URL {
        let hash = SHA256.hash(data: Data(url.absoluteString.utf8))
        let filename = hash.map { String(format: "%02x", $0) }.joined()
        return diskCacheDirectory.appendingPathComponent(filename)
    }

    private func loadFromDisk(url: URL) -> UIImage? {
        let fileURL = diskCacheURL(for: url)
        guard let data = try? Data(contentsOf: fileURL) else { return nil }
        return UIImage(data: data)
    }

    private func saveToDisk(data: Data, url: URL) {
        let fileURL = diskCacheURL(for: url)
        try? data.write(to: fileURL, options: [.atomic])
    }
}
