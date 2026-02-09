//
//  C2BRegisterURLResponse.swift
//  MpesaSDK
//
//  Created by Muktar Aisak on 6/2/2026.
//

import Foundation

/// Response from the C2B Register URL API.
public struct C2BRegisterURLResponse: Decodable {
    /// Global unique identifier for the request.
    public let originatorConversationID: String

    /// Response code. "0" indicates success.
    public let responseCode: String

    /// Description of the response status.
    public let responseDescription: String

    /// Whether the registration was successful.
    public var isSuccessful: Bool {
        responseCode == "0"
    }

    enum CodingKeys: String, CodingKey {
        case originatorConversationID = "OriginatorCoversationID"
        case responseCode = "ResponseCode"
        case responseDescription = "ResponseDescription"
    }
}
