//
//  C2BValidationResponse.swift
//  MpesaSDK
//
//  Created by Muktar Aisak on 8/2/2026.
//

import Foundation

/// Response to send back to M-Pesa for validation requests.
public struct C2BValidationResponse: Encodable {
    /// Result code determining transaction acceptance.
    public let resultCode: String

    /// Description of the result.
    public let resultDesc: String

    enum CodingKeys: String, CodingKey {
        case resultCode = "ResultCode"
        case resultDesc = "ResultDesc"
    }

    /// Creates an acceptance response.
    public static func accept() -> C2BValidationResponse {
        C2BValidationResponse(
            resultCode: C2BValidationResultCode.accepted.rawValue,
            resultDesc: "Accepted"
        )
    }

    /// Creates a rejection response with a specific reason.
    public static func reject(code: C2BValidationResultCode, description: String = "Rejected") -> C2BValidationResponse {
        C2BValidationResponse(
            resultCode: code.rawValue,
            resultDesc: description
        )
    }

    /// Creates a rejection response for invalid phone number.
    public static func rejectInvalidMSISDN() -> C2BValidationResponse {
        reject(code: .invalidMSISDN, description: "Invalid phone number")
    }

    /// Creates a rejection response for invalid account number.
    public static func rejectInvalidAccountNumber() -> C2BValidationResponse {
        reject(code: .invalidAccountNumber, description: "Invalid account number")
    }

    /// Creates a rejection response for invalid amount.
    public static func rejectInvalidAmount() -> C2BValidationResponse {
        reject(code: .invalidAmount, description: "Invalid amount")
    }
}
