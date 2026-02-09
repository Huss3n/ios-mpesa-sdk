//
//  STKPushRequest.swift
//  MpesaSDK
//
//  Created by Muktar Aisak on 10/2/2026.
//

import Foundation

/// Request payload for initiating an STK Push (Lipa Na M-Pesa) transaction.
public struct STKPushRequest: Encodable {
    /// Organization's shortcode (Paybill or Till number).
    public let businessShortCode: String

    /// The Lipa Na M-Pesa passkey provided by Safaricom.
    public let passKey: String

    /// Transaction amount.
    public let amount: Int

    /// Phone number sending money (format: 254XXXXXXXXX).
    public let phoneNumber: String

    /// URL to receive the transaction result callback.
    public let callbackURL: URL

    /// Account reference shown in the USSD prompt. Max 12 characters.
    public let accountReference: String

    /// Description of the transaction. Max 13 characters.
    public let transactionDesc: String

    /// Type of transaction. Defaults to `CustomerPayBillOnline`.
    public let transactionType: STKPushTransactionType

    public init(
        businessShortCode: String,
        passKey: String,
        amount: Int,
        phoneNumber: String,
        callbackURL: URL,
        accountReference: String,
        transactionDesc: String,
        transactionType: STKPushTransactionType = .customerPayBillOnline
    ) {
        self.businessShortCode = businessShortCode
        self.passKey = passKey
        self.amount = amount
        self.phoneNumber = phoneNumber
        self.callbackURL = callbackURL
        self.accountReference = accountReference
        self.transactionDesc = transactionDesc
        self.transactionType = transactionType
    }

    // MARK: - Password & Timestamp Generation

    /// Generates the timestamp in YYYYMMDDHHmmss format.
    static func generateTimestamp(from date: Date = Date()) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyyMMddHHmmss"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(identifier: "Africa/Nairobi")
        return formatter.string(from: date)
    }

    /// Generates the password: base64(BusinessShortCode + Passkey + Timestamp).
    static func generatePassword(
        businessShortCode: String,
        passKey: String,
        timestamp: String
    ) -> String {
        let rawString = businessShortCode + passKey + timestamp
        return Data(rawString.utf8).base64EncodedString()
    }

    // MARK: - Encoding

    enum CodingKeys: String, CodingKey {
        case businessShortCode = "BusinessShortCode"
        case password = "Password"
        case timestamp = "Timestamp"
        case transactionType = "TransactionType"
        case amount = "Amount"
        case partyA = "PartyA"
        case partyB = "PartyB"
        case phoneNumber = "PhoneNumber"
        case callbackURL = "CallBackURL"
        case accountReference = "AccountReference"
        case transactionDesc = "TransactionDesc"
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        let shortCode = Int(businessShortCode) ?? 0
        let timestamp = STKPushRequest.generateTimestamp()
        let password = STKPushRequest.generatePassword(
            businessShortCode: businessShortCode,
            passKey: passKey,
            timestamp: timestamp
        )

        try container.encode(shortCode, forKey: .businessShortCode)
        try container.encode(password, forKey: .password)
        try container.encode(timestamp, forKey: .timestamp)
        try container.encode(transactionType.rawValue, forKey: .transactionType)
        try container.encode(amount, forKey: .amount)
        try container.encode(Int(phoneNumber) ?? 0, forKey: .partyA)
        try container.encode(shortCode, forKey: .partyB)
        try container.encode(Int(phoneNumber) ?? 0, forKey: .phoneNumber)
        try container.encode(callbackURL.absoluteString, forKey: .callbackURL)
        try container.encode(accountReference, forKey: .accountReference)
        try container.encode(transactionDesc, forKey: .transactionDesc)
    }
}
