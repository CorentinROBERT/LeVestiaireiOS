//
//  LoginRequest.swift
//  LeVestaire
//
//  Created by Corentin Robert on 15/06/2026.
//

import Foundation

struct LoginRequest: Encodable, Equatable {
    let email: String
    let password: String
}
