//
//  C2BService.swift
//  MpesaSDK
//
//  Created by Muktar Aisak on 8/2/2026.
//

import Foundation

/// Service for C2B (Customer to Business) API operations.
public final class C2BService: Sendable {
    private let apiClient: APIClientProtocol
    private let tokenManager: TokenManager

    init(apiClient: APIClientProtocol, tokenManager: TokenManager) {
        self.apiClient = apiClient
        self.tokenManager = tokenManager
    }

    // MARK: - Register URLs

    /// Registers validation and confirmation URLs for C2B payments.
    ///
    /// - Parameter request: The URL registration request details.
    /// - Returns: The registration response.
    /// - Throws: `MpesaError` if the request fails.
    ///
    /// - Note: In sandbox, URLs can be registered multiple times.
    ///         In production, this is a one-time operation.
    public func registerURLs(_ request: C2BRegisterURLRequest) async throws -> C2BRegisterURLResponse {
        let token = try await tokenManager.getValidToken()

        return try await apiClient.send(
            endpoint: .c2bRegisterURL,
            body: request,
            headers: ["Authorization": "Bearer \(token)"]
        )
    }

    /// Registers validation and confirmation URLs for C2B payments.
    ///
    /// - Parameters:
    ///   - shortCode: Organization's shortcode (Paybill or Till number).
    ///   - responseType: Default action when validation URL is unreachable.
    ///   - confirmationURL: URL to receive payment confirmations.
    ///   - validationURL: URL to receive validation requests.
    /// - Returns: The registration response.
    public func registerURLs(
        shortCode: String,
        responseType: C2BResponseType,
        confirmationURL: URL,
        validationURL: URL
    ) async throws -> C2BRegisterURLResponse {
        let request = C2BRegisterURLRequest(
            shortCode: shortCode,
            responseType: responseType,
            confirmationURL: confirmationURL,
            validationURL: validationURL
        )
        return try await registerURLs(request)
    }

    // MARK: - Simulate Transaction (Sandbox Only)

    /// Simulates a C2B transaction. Only available in sandbox environment.
    ///
    /// - Parameter request: The simulation request details.
    /// - Returns: The simulation response.
    /// - Throws: `MpesaError` if the request fails.
    ///
    /// - Warning: This API is not available in production.
    ///            Use M-Pesa App, USSD, or SIM Toolkit for real transactions.
    public func simulate(_ request: C2BSimulateRequest) async throws -> C2BSimulateResponse {
        let token = try await tokenManager.getValidToken()

        return try await apiClient.send(
            endpoint: .c2bSimulate,
            body: request,
            headers: ["Authorization": "Bearer \(token)"]
        )
    }

    /// Simulates a C2B transaction. Only available in sandbox environment.
    ///
    /// - Parameters:
    ///   - shortCode: Organization's shortcode.
    ///   - commandID: Type of transaction (PayBill or BuyGoods).
    ///   - amount: Amount to transact.
    ///   - msisdn: Phone number to debit (format: 254XXXXXXXXX).
    ///   - billRefNumber: Account reference for PayBill. Nil for BuyGoods.
    /// - Returns: The simulation response.
    public func simulate(
        shortCode: String,
        commandID: C2BCommandID,
        amount: Int,
        msisdn: String,
        billRefNumber: String? = nil
    ) async throws -> C2BSimulateResponse {
        let request = C2BSimulateRequest(
            shortCode: shortCode,
            commandID: commandID,
            amount: amount,
            msisdn: msisdn,
            billRefNumber: billRefNumber
        )
        return try await simulate(request)
    }

    // MARK: - Callback Parsing

    /// Parses a C2B callback payload from JSON data.
    ///
    /// Use this method in your server to parse incoming callbacks.
    ///
    /// - Parameter data: The raw JSON data from M-Pesa callback.
    /// - Returns: The parsed callback payload.
    /// - Throws: `MpesaError.decodingError` if parsing fails.
    public static func parseCallback(from data: Data) throws -> C2BCallback {
        do {
            return try JSONDecoder().decode(C2BCallback.self, from: data)
        } catch {
            throw MpesaError.decodingError(error)
        }
    }
}
