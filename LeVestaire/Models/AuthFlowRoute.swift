//
//  AuthFlowRoute.swift
//  LeVestaire
//
//  Created by Corentin Robert on 15/06/2026.
//

import Foundation

enum AuthFlowRoute: Hashable {
    case register
    case forgetPassword
    case resetPassword(token: String?)
}
