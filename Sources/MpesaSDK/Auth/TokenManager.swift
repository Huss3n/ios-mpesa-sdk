//
//  TokenManager.swift
//  MpesaSDK
//
//  Created by Muktar Aisak on 5/2/2026.
//

import Foundation

/// Manages OAuth token lifecycle with thread-safe access.
actor TokenManager {
    private let configuration: MpesaConfiguration
    private let apiClient: APIClientProtocol

    private var cachedToken: String?
    private var tokenExpiryDate: Date?

    /// Buffer time before token expiry to refresh (5 minutes).
    private let expiryBuffer: TimeInterval = 300

    init(configuration: MpesaConfiguration, apiClient: APIClientProtocol) {
        self.configuration = configuration
        self.apiClient = apiClient
    }

    /// Returns a valid access token, refreshing if necessary.
    func getValidToken() async throws -> String {
        if let token = cachedToken, let expiry = tokenExpiryDate, Date() < expiry {
            return token
        }
        return try await refreshToken()
    }

    /// Forces a token refresh.
    func refreshToken() async throws -> String {
        let headers = [
            "Authorization": "Basic \(configuration.basicAuthCredentials)"
        ]

        let response: AccessToken = try await apiClient.send(
            endpoint: .oauth,
            body: nil as String?,
            headers: headers
        )

        cachedToken = response.accessToken
        tokenExpiryDate = Date().addingTimeInterval(response.expirySeconds - expiryBuffer)

        return response.accessToken
    }

    /// Clears the cached token.
    func clearToken() {
        cachedToken = nil
        tokenExpiryDate = nil
    }
}
