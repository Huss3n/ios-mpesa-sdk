//
//  C2BCallback.swift
//  MpesaSDK
//
//  Created by Muktar Aisak on 7/2/2026.
//

import Foundation

/// Callback payload received from M-Pesa for C2B transactions.
/// Used for both validation and confirmation callbacks.
public struct C2BCallback: Decodable {
    /// The transaction type (Pay Bill or Buy Goods).
    public let transactionType: String

    /// Unique M-Pesa transaction ID.
    public let transID: String

    /// Transaction timestamp (format: YYYYMMDDHHmmss).
    public let transTime: String

    /// Amount transacted.
    public let transAmount: String

    /// Organization's shortcode.
    public let businessShortCode: String

    /// Account reference for PayBill transactions.
    public let billRefNumber: String

    /// Invoice number (if applicable).
    public let invoiceNumber: String

    /// Organization's account balance after transaction.
    /// Empty for validation requests.
    public let orgAccountBalance: String

    /// Partner's transaction ID for tracking.
    public let thirdPartyTransID: String

    /// Masked customer phone number.
    public let msisdn: String

    /// Customer's first name.
    public let firstName: String

    /// Customer's middle name.
    public let middleName: String

    /// Customer's last name.
    public let lastName: String

    enum CodingKeys: String, CodingKey {
        case transactionType = "TransactionType"
        case transID = "TransID"
        case transTime = "TransTime"
        case transAmount = "TransAmount"
        case businessShortCode = "BusinessShortCode"
        case billRefNumber = "BillRefNumber"
        case invoiceNumber = "InvoiceNumber"
        case orgAccountBalance = "OrgAccountBalance"
        case thirdPartyTransID = "ThirdPartyTransID"
        case msisdn = "MSISDN"
        case firstName = "FirstName"
        case middleName = "MiddleName"
        case lastName = "LastName"
    }

    /// Parsed transaction date.
    public var transactionDate: Date? {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyyMMddHHmmss"
        return formatter.date(from: transTime)
    }

    /// Parsed transaction amount as Decimal.
    public var amount: Decimal? {
        Decimal(string: transAmount)
    }

    /// Full customer name.
    public var customerName: String {
        [firstName, middleName, lastName]
            .filter { !$0.isEmpty }
            .joined(separator: " ")
    }
}
