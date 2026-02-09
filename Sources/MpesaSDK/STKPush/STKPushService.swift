//
//  STKPushService.swift
//  MpesaSDK
//
//  Created by Muktar Aisak on 10/2/2026.
//

import Foundation

/// Service for STK Push (Lipa Na M-Pesa) API operations.
///
/// STK Push is merchant-initiated — the app sends a request and
/// M-Pesa pushes a payment prompt to the customer's phone.
public final class STKPushService: Sendable {
    private let apiClient: APIClientProtocol
    private let tokenManager: TokenManager

    init(apiClient: APIClientProtocol, tokenManager: TokenManager) {
        self.apiClient = apiClient
        self.tokenManager = tokenManager
    }

    // MARK: - Initiate Payment

    /// Initiates an STK Push payment request.
    ///
    /// - Parameter request: The STK Push request details.
    /// - Returns: The STK Push response with checkout request ID.
    /// - Throws: `MpesaError` if the request fails.
    public func initiatePayment(_ request: STKPushRequest) async throws -> STKPushResponse {
        let token = try await tokenManager.getValidToken()

        return try await apiClient.send(
            endpoint: .stkPush,
            body: request,
            headers: ["Authorization": "Bearer \(token)"]
        )
    }

    /// Initiates an STK Push payment request with individual parameters.
    ///
    /// For full control over transaction type and description, use the
    /// `initiatePayment(_ request:)` overload with an `STKPushRequest` object.
    ///
    /// - Parameters:
    ///   - businessShortCode: Organization's shortcode (Paybill or Till number).
    ///   - passKey: The Lipa Na M-Pesa passkey from Safaricom.
    ///   - amount: Transaction amount.
    ///   - phoneNumber: Phone number to receive the USSD prompt (format: 254XXXXXXXXX).
    ///   - callbackURL: URL to receive the transaction result.
    ///   - accountReference: Account reference shown in USSD prompt. Max 12 characters.
    /// - Returns: The STK Push response with checkout request ID.
    public func initiatePayment(
        businessShortCode: String,
        passKey: String,
        amount: Int,
        phoneNumber: String,
        callbackURL: URL,
        accountReference: String
    ) async throws -> STKPushResponse {
        let request = STKPushRequest(
            businessShortCode: businessShortCode,
            passKey: passKey,
            amount: amount,
            phoneNumber: phoneNumber,
            callbackURL: callbackURL,
            accountReference: accountReference,
            transactionDesc: "Payment"
        )
        return try await initiatePayment(request)
    }

    // MARK: - Callback Parsing

    /// Parses an STK Push callback payload from JSON data.
    ///
    /// Use this method in your server to parse incoming callbacks.
    ///
    /// - Parameter data: The raw JSON data from M-Pesa callback.
    /// - Returns: The parsed callback payload.
    /// - Throws: `MpesaError.decodingError` if parsing fails.
    public static func parseCallback(from data: Data) throws -> STKPushCallback {
        do {
            return try JSONDecoder().decode(STKPushCallback.self, from: data)
        } catch {
            throw MpesaError.decodingError(error)
        }
    }
}
