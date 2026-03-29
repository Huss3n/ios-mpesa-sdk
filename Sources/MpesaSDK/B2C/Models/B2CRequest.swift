//
//  B2CRequest.swift
//  MpesaSDK
//
//  Created by Muktar Aisak on 29/3/2026.
//

import Foundation

/// Request payload for B2C (Business to Customer) payment transactions.
///
/// Sends money from a business shortcode to a customer's M-PESA number.
/// The `securityCredential` must be pre-encrypted by the caller using the M-Pesa public certificate.
public struct B2CRequest: Encodable, Sendable {
    /// Unique identifier for this request to prevent duplicate disbursements.
    /// Can also be used to query transaction status.
    public let originatorConversationID: String

    /// Username of the API operator as set on the M-PESA portal.
    public let initiatorName: String

    /// Encrypted credential of the API operator.
    public let securityCredential: String

    /// The type of B2C transaction.
    public let commandID: B2CCommandID

    /// Transaction amount in KES.
    public let amount: Int

    /// B2C organization shortcode from which the money is sent.
    public let partyA: String

    /// Customer's mobile number to receive the money (format: 254XXXXXXXXX).
    public let partyB: String

    /// Additional information sent with the request. 2–100 characters.
    public let remarks: String

    /// URL to receive the transaction result.
    public let resultURL: URL

    /// URL for notification if the request times out.
    public let queueTimeOutURL: URL

    /// Additional information sent with the request. 1–100 characters. Optional.
    public let occasion: String?

    // swiftlint:disable function_parameter_count
    public init(
        originatorConversationID: String,
        initiatorName: String,
        securityCredential: String,
        commandID: B2CCommandID = .businessPayment,
        amount: Int,
        partyA: String,
        partyB: String,
        remarks: String = "OK",
        resultURL: URL,
        queueTimeOutURL: URL,
        occasion: String? = nil
    ) {
    // swiftlint:enable function_parameter_count
        self.originatorConversationID = originatorConversationID
        self.initiatorName = initiatorName
        self.securityCredential = securityCredential
        self.commandID = commandID
        self.amount = amount
        self.partyA = partyA
        self.partyB = partyB
        self.remarks = remarks
        self.resultURL = resultURL
        self.queueTimeOutURL = queueTimeOutURL
        self.occasion = occasion
    }

    // MARK: - Encoding

    enum CodingKeys: String, CodingKey {
        case originatorConversationID = "OriginatorConversationID"
        case initiatorName = "InitiatorName"
        case securityCredential = "SecurityCredential"
        case commandID = "CommandID"
        case amount = "Amount"
        case partyA = "PartyA"
        case partyB = "PartyB"
        case remarks = "Remarks"
        case queueTimeOutURL = "QueueTimeOutURL"
        case resultURL = "ResultURL"
        // Daraja API uses "Occassion" (double 's')
        case occasion = "Occassion"
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        try container.encode(originatorConversationID, forKey: .originatorConversationID)
        try container.encode(initiatorName, forKey: .initiatorName)
        try container.encode(securityCredential, forKey: .securityCredential)
        try container.encode(commandID, forKey: .commandID)
        try container.encode(String(amount), forKey: .amount)
        try container.encode(partyA, forKey: .partyA)
        try container.encode(partyB, forKey: .partyB)
        try container.encode(remarks, forKey: .remarks)
        try container.encode(queueTimeOutURL.absoluteString, forKey: .queueTimeOutURL)
        try container.encode(resultURL.absoluteString, forKey: .resultURL)

        if let occasion = occasion {
            try container.encode(occasion, forKey: .occasion)
        }
    }
}
