//
//  C2BRegisterURLRequest.swift
//  MpesaSDK
//
//  Created by Muktar Aisak on 6/2/2026.
//

import Foundation

/// Request payload for registering C2B callback URLs.
public struct C2BRegisterURLRequest: Encodable {
    /// Organization's shortcode (Paybill or Till number).
    public let shortCode: String

    /// Default action when validation URL is unreachable.
    public let responseType: C2BResponseType

    /// URL to receive confirmation notifications after payment completion.
    public let confirmationURL: URL

    /// URL to receive validation requests before payment completion.
    /// Only called if external validation is enabled for the shortcode.
    public let validationURL: URL

    public init(
        shortCode: String,
        responseType: C2BResponseType,
        confirmationURL: URL,
        validationURL: URL
    ) {
        self.shortCode = shortCode
        self.responseType = responseType
        self.confirmationURL = confirmationURL
        self.validationURL = validationURL
    }

    enum CodingKeys: String, CodingKey {
        case shortCode = "ShortCode"
        case responseType = "ResponseType"
        case confirmationURL = "ConfirmationURL"
        case validationURL = "ValidationURL"
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(shortCode, forKey: .shortCode)
        try container.encode(responseType.rawValue, forKey: .responseType)
        try container.encode(confirmationURL.absoluteString, forKey: .confirmationURL)
        try container.encode(validationURL.absoluteString, forKey: .validationURL)
    }
}
