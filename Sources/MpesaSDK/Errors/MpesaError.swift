//
//  MpesaError.swift
//  MpesaSDK
//
//  Created by Muktar Aisak on 2/2/2026.
//

import Foundation

/// Errors that can occur when using the M-Pesa SDK.
public enum MpesaError: LocalizedError {
    case invalidConfiguration(String)
    case authenticationFailed(String)
    case invalidRequest(String)
    case networkError(Error)
    case serverError(statusCode: Int, message: String)
    case apiError(code: String, message: String)
    case decodingError(Error)
    case unknown(String)

    public var errorDescription: String? {
        switch self {
        case .invalidConfiguration(let message):
            return "Invalid configuration: \(message)"
        case .authenticationFailed(let message):
            return "Authentication failed: \(message)"
        case .invalidRequest(let message):
            return "Invalid request: \(message)"
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        case .serverError(let statusCode, let message):
            return "Server error (\(statusCode)): \(message)"
        case .apiError(let code, let message):
            return "API error (\(code)): \(message)"
        case .decodingError(let error):
            return "Decoding error: \(error.localizedDescription)"
        case .unknown(let message):
            return "Unknown error: \(message)"
        }
    }
}

/// API error response from M-Pesa.
struct APIErrorResponse: Decodable {
    let requestId: String?
    let errorCode: String?
    let errorMessage: String?

    enum CodingKeys: String, CodingKey {
        case requestId
        case errorCode
        case errorMessage
    }
}
