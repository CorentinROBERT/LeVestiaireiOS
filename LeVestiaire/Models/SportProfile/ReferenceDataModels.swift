//
//  ReferenceDataModels.swift
//  LeVestaire
//
//  Created by Corentin Robert on 16/06/2026.
//

import Foundation

struct LeagueReference: Identifiable, Equatable {
    let key: String
    let name: String
    let country: String?

    var id: String { key }
}

struct LeagueCatalogEntry: Decodable, Equatable {
    let name: String
    let country: String
    let teams: [String]
}

typealias LeagueCatalog = [String: LeagueCatalogEntry]
