//
//  ReferenceDataService.swift
//  LeVestaire
//
//  Created by Corentin Robert on 16/06/2026.
//

import Foundation

final class ReferenceDataService {
    static let shared = ReferenceDataService()

    private static let resourceName = "LeaguesReference"
    private let catalog: LeagueCatalog

    init(bundle: Bundle = .main) {
        catalog = Self.loadCatalog(from: bundle)
    }

    func leagues() -> [LeagueReference] {
        catalog
            .map { key, entry in
                LeagueReference(key: key, name: entry.name, country: entry.country)
            }
            .sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
    }

    func teams(forLeague leagueKey: String) -> [String] {
        catalog[leagueKey]?.teams ?? []
    }

    private static func loadCatalog(from bundle: Bundle) -> LeagueCatalog {
        guard let url = bundle.url(forResource: resourceName, withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let catalog = try? JSONDecoder().decode(LeagueCatalog.self, from: data) else {
            return [:]
        }

        return catalog
    }
}
