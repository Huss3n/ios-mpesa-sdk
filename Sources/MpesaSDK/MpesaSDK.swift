//
//  MpesaSDK.swift
//  MpesaSDK
//
//  Created by Muktar Aisak on 9/2/2026.
//

import Foundation

/// Main entry point for the M-Pesa SDK.
public final class Mpesa: Sendable {
    private let configuration: MpesaConfiguration
    private let apiClient: APIClient
    private let tokenManager: TokenManager

    /// C2B (Customer to Business) service for receiving payments.
    public let c2b: C2BService

    /// STK Push (Lipa Na M-Pesa) service for merchant-initiated payments.
    public let stkPush: STKPushService

    /// Creates a new M-Pesa SDK instance.
    ///
    /// - Parameter configuration: The SDK configuration with credentials and environment.
    public init(configuration: MpesaConfiguration) {
        self.configuration = configuration
        self.apiClient = APIClient(baseURL: configuration.environment.baseURL)
        self.tokenManager = TokenManager(configuration: configuration, apiClient: apiClient)
        self.c2b = C2BService(apiClient: apiClient, tokenManager: tokenManager)
        self.stkPush = STKPushService(apiClient: apiClient, tokenManager: tokenManager)
    }

    /// Creates a new M-Pesa SDK instance with individual parameters.
    ///
    /// - Parameters:
    ///   - consumerKey: Your M-Pesa API consumer key.
    ///   - consumerSecret: Your M-Pesa API consumer secret.
    ///   - environment: The target environment (sandbox or production).
    public convenience init(
        consumerKey: String,
        consumerSecret: String,
        environment: MpesaEnvironment = .sandbox
    ) {
        let config = MpesaConfiguration(
            consumerKey: consumerKey,
            consumerSecret: consumerSecret,
            environment: environment
        )
        self.init(configuration: config)
    }
}

// MARK: - Public Type Exports

public typealias Environment = MpesaEnvironment
public typealias Configuration = MpesaConfiguration
