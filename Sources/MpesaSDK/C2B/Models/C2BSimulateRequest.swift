//
//  C2BSimulateRequest.swift
//  MpesaSDK
//
//  Created by Muktar Aisak on 7/2/2026.
//

import Foundation

/// Request payload for simulating a C2B transaction (sandbox only).
public struct C2BSimulateRequest: Encodable {
    /// Organization's shortcode (Paybill or Till number).
    public let shortCode: String

    /// Type of transaction to simulate.
    public let commandID: C2BCommandID

    /// Amount to transact.
    public let amount: Int

    /// Phone number to debit (format: 254XXXXXXXXX).
    public let msisdn: String

    /// Account reference for PayBill transactions. Use nil for Buy Goods.
    public let billRefNumber: String?

    public init(
        shortCode: String,
        commandID: C2BCommandID,
        amount: Int,
        msisdn: String,
        billRefNumber: String? = nil
    ) {
        self.shortCode = shortCode
        self.commandID = commandID
        self.amount = amount
        self.msisdn = msisdn
        self.billRefNumber = billRefNumber
    }

    enum CodingKeys: String, CodingKey {
        case shortCode = "ShortCode"
        case commandID = "CommandID"
        case amount = "Amount"
        case msisdn = "Msisdn"
        case billRefNumber = "BillRefNumber"
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(Int(shortCode) ?? 0, forKey: .shortCode)
        try container.encode(commandID.rawValue, forKey: .commandID)
        try container.encode(amount, forKey: .amount)
        try container.encode(Int(msisdn) ?? 0, forKey: .msisdn)
        try container.encode(billRefNumber ?? "", forKey: .billRefNumber)
    }
}
