//
//  APIAuthIntercepting.swift
//  LeVestaire
//
//  Created by Corentin Robert on 17/06/2026.
//

import Foundation

@MainActor
protocol APIAuthIntercepting: AnyObject {
    func refreshAccessToken() async -> String?
    func forceLogout() async
}
