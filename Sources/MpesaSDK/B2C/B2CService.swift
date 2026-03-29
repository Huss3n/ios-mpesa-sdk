//
//  B2CService.swift
//  MpesaSDK
//
//  Created by Muktar Aisak on 29/3/2026.
//

import Foundation

/// Service for B2C (Business to Customer) payment API operations.
///
/// Makes payments from a business shortcode to customers' M-PESA numbers
/// (Bulk Disbursements). The API response confirms acceptance; the actual
/// result arrives asynchronously via the `ResultURL` callback.
public final class B2CService: Sendable {
    private let apiClient: APIClientProtocol
    private let tokenManager: TokenManager

    init(apiClient: APIClientProtocol, tokenManager: TokenManager) {
        self.apiClient = apiClient
        self.tokenManager = tokenManager
    }

    // MARK: - Payment

    /// Initiates a B2C payment request.
    ///
    /// - Parameter request: The B2C payment request details.
    /// - Returns: The acceptance response confirming the request was received.
    /// - Throws: `MpesaError` if the request fails.
    public func payment(_ request: B2CRequest) async throws -> B2CResponse {
        let token = try await tokenManager.getValidToken()

        return try await apiClient.send(
            endpoint: .b2c,
            body: request,
            headers: ["Authorization": "Bearer \(token)"]
        )
    }

    // swiftlint:disable function_parameter_count
    /// Initiates a B2C payment request with individual parameters.
    ///
    /// For full control over optional fields like `occasion`,
    /// use the `payment(_ request:)` overload with a `B2CRequest` object.
    ///
    /// - Parameters:
    ///   - originatorConversationID: Unique ID to prevent duplicate disbursements.
    ///   - initiatorName: Username of the API operator.
    ///   - securityCredential: Encrypted credential of the API operator.
    ///   - commandID: Type of B2C transaction. Default: `.businessPayment`.
    ///   - amount: Transaction amount in KES.
    ///   - partyA: B2C organization shortcode (debit account).
    ///   - partyB: Customer's mobile number (format: 254XXXXXXXXX).
    ///   - remarks: Additional information. 2–100 characters. Default: `"OK"`.
    ///   - resultURL: URL to receive the transaction result.
    ///   - queueTimeOutURL: URL for timeout notification.
    /// - Returns: The acceptance response confirming the request was received.
    public func payment(
        originatorConversationID: String,
        initiatorName: String,
        securityCredential: String,
        commandID: B2CCommandID = .businessPayment,
        amount: Int,
        partyA: String,
        partyB: String,
        remarks: String = "OK",
        resultURL: URL,
        queueTimeOutURL: URL
    ) async throws -> B2CResponse {
    // swiftlint:enable function_parameter_count
        let request = B2CRequest(
            originatorConversationID: originatorConversationID,
            initiatorName: initiatorName,
            securityCredential: securityCredential,
            commandID: commandID,
            amount: amount,
            partyA: partyA,
            partyB: partyB,
            remarks: remarks,
            resultURL: resultURL,
            queueTimeOutURL: queueTimeOutURL
        )
        return try await payment(request)
    }

    // MARK: - Result Parsing

    /// Parses a B2C result payload from JSON data.
    ///
    /// Use this method in your server to parse incoming result callbacks.
    ///
    /// - Parameter data: The raw JSON data from M-Pesa result callback.
    /// - Returns: The parsed result payload.
    /// - Throws: `MpesaError.decodingError` if parsing fails.
    public static func parseResult(from data: Data) throws -> B2CResult {
        do {
            return try JSONDecoder().decode(B2CResult.self, from: data)
        } catch {
            throw MpesaError.decodingError(error)
        }
    }
}
