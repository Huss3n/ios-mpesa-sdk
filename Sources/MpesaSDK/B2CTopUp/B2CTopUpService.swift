//
//  B2CTopUpService.swift
//  MpesaSDK
//
//  Created by Muktar Aisak on 12/2/2026.
//

import Foundation

/// Service for B2C Account Top Up API operations.
///
/// Loads funds into a B2C shortcode utility account for disbursement.
/// The API response confirms acceptance; the actual result arrives
/// asynchronously via the `ResultURL` callback.
public final class B2CTopUpService: Sendable {
    private let apiClient: APIClientProtocol
    private let tokenManager: TokenManager

    init(apiClient: APIClientProtocol, tokenManager: TokenManager) {
        self.apiClient = apiClient
        self.tokenManager = tokenManager
    }

    // MARK: - Top Up

    /// Initiates a B2C Account Top Up request.
    ///
    /// - Parameter request: The top up request details.
    /// - Returns: The acceptance response confirming the request was received.
    /// - Throws: `MpesaError` if the request fails.
    public func topUp(_ request: B2CTopUpRequest) async throws -> B2CTopUpResponse {
        let token = try await tokenManager.getValidToken()

        return try await apiClient.send(
            endpoint: .b2cTopUp,
            body: request,
            headers: ["Authorization": "Bearer \(token)"]
        )
    }

    // swiftlint:disable function_parameter_count
    /// Initiates a B2C Account Top Up request with individual parameters.
    ///
    /// For full control over optional fields like `requester` and `remarks`,
    /// use the `topUp(_ request:)` overload with a `B2CTopUpRequest` object.
    ///
    /// - Parameters:
    ///   - initiator: The name of the API operator.
    ///   - securityCredential: Encrypted credential of the API operator.
    ///   - partyA: Organization's shortcode (debit account).
    ///   - partyB: Organization's shortcode (credit account).
    ///   - amount: Transaction amount.
    ///   - accountReference: Account reference for the recipient.
    /// - Returns: The acceptance response confirming the request was received.
    public func topUp(
        initiator: String,
        securityCredential: String,
        partyA: String,
        partyB: String,
        amount: Int,
        accountReference: String,
        resultURL: URL,
        queueTimeOutURL: URL
    ) async throws -> B2CTopUpResponse {
    // swiftlint:enable function_parameter_count
        let request = B2CTopUpRequest(
            initiator: initiator,
            securityCredential: securityCredential,
            partyA: partyA,
            partyB: partyB,
            amount: amount,
            accountReference: accountReference,
            resultURL: resultURL,
            queueTimeOutURL: queueTimeOutURL
        )
        return try await topUp(request)
    }

    // MARK: - Result Parsing

    /// Parses a B2C Account Top Up result payload from JSON data.
    ///
    /// Use this method in your server to parse incoming result callbacks.
    ///
    /// - Parameter data: The raw JSON data from M-Pesa result callback.
    /// - Returns: The parsed result payload.
    /// - Throws: `MpesaError.decodingError` if parsing fails.
    public static func parseResult(from data: Data) throws -> B2CTopUpResult {
        do {
            return try JSONDecoder().decode(B2CTopUpResult.self, from: data)
        } catch {
            throw MpesaError.decodingError(error)
        }
    }
}
