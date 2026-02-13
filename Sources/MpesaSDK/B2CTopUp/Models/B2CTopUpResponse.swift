//
//  B2CTopUpResponse.swift
//  MpesaSDK
//
//  Created by Muktar Aisak on 12/2/2026.
//

/// Acceptance response from the B2C Account Top Up API.
///
/// This confirms the request was accepted for processing.
/// The actual result is delivered asynchronously via the `ResultURL`.
public struct B2CTopUpResponse: Decodable, Sendable {
    /// Unique identifier for the originator's conversation.
    public let originatorConversationID: String

    /// Unique identifier for the conversation.
    public let conversationID: String

    /// Response code. "0" indicates the request was accepted.
    public let responseCode: String

    /// Description of the response status.
    public let responseDescription: String

    /// Whether the request was accepted for processing.
    public var isSuccessful: Bool {
        Int(responseCode) == 0
    }

    init(
        originatorConversationID: String,
        conversationID: String,
        responseCode: String,
        responseDescription: String
    ) {
        self.originatorConversationID = originatorConversationID
        self.conversationID = conversationID
        self.responseCode = responseCode
        self.responseDescription = responseDescription
    }

    enum CodingKeys: String, CodingKey {
        case originatorConversationID = "OriginatorConversationID"
        case conversationID = "ConversationID"
        case responseCode = "ResponseCode"
        case responseDescription = "ResponseDescription"
    }
}
