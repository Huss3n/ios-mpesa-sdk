//
//  MpesaConfiguration.swift
//  MpesaSDK
//
//  Created by Muktar Aisak on 3/2/2026.
//

import Foundation

/// Configuration for the M-Pesa SDK.
public struct MpesaConfiguration {
    public let consumerKey: String
    public let consumerSecret: String
    public let environment: MpesaEnvironment

    public init(
        consumerKey: String,
        consumerSecret: String,
        environment: MpesaEnvironment = .sandbox
    ) {
        self.consumerKey = consumerKey
        self.consumerSecret = consumerSecret
        self.environment = environment
    }

    var basicAuthCredentials: String {
        let credentials = "\(consumerKey):\(consumerSecret)"
        return Data(credentials.utf8).base64EncodedString()
    }
}
