//
//  AccountActionResponse.swift
//  LeVestaire
//
//  Created by Corentin Robert on 16/06/2026.
//

import Foundation

struct AccountActionResponse: Decodable, Equatable {
    let success: Bool
    let message: String?
    let error: String?
    let data: User?

    var userFacingMessage: String? {
        message ?? error
    }

    init(
        success: Bool = false,
        message: String? = nil,
        error: String? = nil,
        data: User? = nil
    ) {
        self.success = success
        self.message = message
        self.error = error
        self.data = data
    }
}
