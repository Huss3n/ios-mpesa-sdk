//
//  AccessToken.swift
//  MpesaSDK
//
//  Created by Muktar Aisak on 5/2/2026.
//

import Foundation

/// OAuth access token response from M-Pesa.
struct AccessToken: Decodable {
    let accessToken: String
    let expiresIn: String

    enum CodingKeys: String, CodingKey {
        case accessToken = "access_token"
        case expiresIn = "expires_in"
    }

    /// Token expiry duration in seconds.
    var expirySeconds: TimeInterval {
        TimeInterval(expiresIn) ?? 3599
    }
}
