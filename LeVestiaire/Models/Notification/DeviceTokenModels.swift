//
//  DeviceTokenModels.swift
//  LeVestaire
//

import Foundation

struct RegisterDeviceTokenRequest: Encodable {
    let token: String
    let platform: String
    let deviceId: String?
    let appVersion: String?
    let locale: String?
}

struct UnregisterDeviceTokenRequest: Encodable {
    let token: String
}

struct TestPushNotificationResponse: Decodable {
    let success: Bool?
    let message: String?
    let error: String?
}
