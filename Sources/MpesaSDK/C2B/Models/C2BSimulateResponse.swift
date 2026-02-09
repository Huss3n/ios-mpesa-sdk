//
//  C2BSimulateResponse.swift
//  MpesaSDK
//
//  Created by Muktar Aisak on 7/2/2026.
//

import Foundation

/// Response from the C2B Simulate API (sandbox only).
public struct C2BSimulateResponse: Decodable {
    /// Global unique identifier for the request.
    public let originatorConversationID: String

    /// Response code. "0" indicates success.
    public let responseCode: String

    /// Description of the response status.
    public let responseDescription: String

    /// Whether the simulation was successful.
    public var isSuccessful: Bool {
        Int(responseCode) == 0
    }

    init(originatorConversationID: String, responseCode: String, responseDescription: String) {
        self.originatorConversationID = originatorConversationID
        self.responseCode = responseCode
        self.responseDescription = responseDescription
    }

    enum CodingKeys: String, CodingKey {
        case originatorConversationID = "OriginatorCoversationID"
        case responseCode = "ResponseCode"
        case responseDescription = "ResponseDescription"
    }
}
