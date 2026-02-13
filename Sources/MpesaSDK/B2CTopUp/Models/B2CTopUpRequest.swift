//
//  B2CTopUpRequest.swift
//  MpesaSDK
//
//  Created by Muktar Aisak on 12/2/2026.
//

import Foundation

/// Request payload for B2C Account Top Up transactions.
///
/// Loads funds into a B2C shortcode utility account for disbursement.
/// The `securityCredential` must be pre-encrypted by the caller.
public struct B2CTopUpRequest: Encodable, Sendable {
    /// The name of the API operator (initiator) as set on the Daraja portal.
    public let initiator: String

    /// Encrypted credential of the API operator. Must be pre-encrypted using the M-Pesa public key.
    public let securityCredential: String

    /// Organization's shortcode (debit account).
    public let partyA: String

    /// Organization's shortcode (credit account).
    public let partyB: String

    /// Transaction amount.
    public let amount: Int

    /// Account reference for the recipient.
    public let accountReference: String

    /// URL to receive the transaction result.
    public let resultURL: URL

    /// URL to receive a notification if the request times out.
    public let queueTimeOutURL: URL

    /// Phone number of the requester. Optional.
    public let requester: String?

    /// Comments about the transaction. Max 100 characters. Optional.
    public let remarks: String?

    public init(
        initiator: String,
        securityCredential: String,
        partyA: String,
        partyB: String,
        amount: Int,
        accountReference: String,
        resultURL: URL,
        queueTimeOutURL: URL,
        requester: String? = nil,
        remarks: String? = nil
    ) {
        self.initiator = initiator
        self.securityCredential = securityCredential
        self.partyA = partyA
        self.partyB = partyB
        self.amount = amount
        self.accountReference = accountReference
        self.resultURL = resultURL
        self.queueTimeOutURL = queueTimeOutURL
        self.requester = requester
        self.remarks = remarks
    }

    // MARK: - Encoding

    enum CodingKeys: String, CodingKey {
        case initiator = "Initiator"
        case securityCredential = "SecurityCredential"
        case commandID = "CommandID"
        case senderIdentifierType = "SenderIdentifierType"
        case recieverIdentifierType = "RecieverIdentifierType"
        case amount = "Amount"
        case partyA = "PartyA"
        case partyB = "PartyB"
        case accountReference = "AccountReference"
        case requester = "Requester"
        case remarks = "Remarks"
        case queueTimeOutURL = "QueueTimeOutURL"
        case resultURL = "ResultURL"
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        try container.encode(initiator, forKey: .initiator)
        try container.encode(securityCredential, forKey: .securityCredential)
        try container.encode("BusinessPayToBulk", forKey: .commandID)
        try container.encode("4", forKey: .senderIdentifierType)
        try container.encode("4", forKey: .recieverIdentifierType)
        try container.encode(String(amount), forKey: .amount)
        try container.encode(partyA, forKey: .partyA)
        try container.encode(partyB, forKey: .partyB)
        try container.encode(accountReference, forKey: .accountReference)
        try container.encode(remarks ?? "OK", forKey: .remarks)
        try container.encode(queueTimeOutURL.absoluteString, forKey: .queueTimeOutURL)
        try container.encode(resultURL.absoluteString, forKey: .resultURL)

        if let requester = requester {
            try container.encode(requester, forKey: .requester)
        }
    }
}
