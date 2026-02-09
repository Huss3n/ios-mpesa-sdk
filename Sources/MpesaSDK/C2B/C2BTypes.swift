//
//  C2BTypes.swift
//  MpesaSDK
//
//  Created by Muktar Aisak on 6/2/2026.
//

import Foundation

// MARK: - Response Type

/// Specifies the default action when validation URL is unreachable.
public enum C2BResponseType: String, Encodable {
    /// M-Pesa will automatically complete the transaction.
    case completed = "Completed"
    /// M-Pesa will automatically cancel the transaction.
    case cancelled = "Cancelled"
}

// MARK: - Command ID

/// Defines the type of C2B transaction.
public enum C2BCommandID: String, Encodable {
    /// Payment to a till number (Buy Goods).
    case customerBuyGoodsOnline = "CustomerBuyGoodsOnline"
    /// Payment to a paybill number.
    case customerPayBillOnline = "CustomerPayBillOnline"
}

// MARK: - Transaction Type

/// The transaction type received in callbacks.
public enum C2BTransactionType: String, Decodable {
    case payBill = "Pay Bill"
    case buyGoods = "Buy Goods"
}

// MARK: - Validation Result Codes

/// Result codes for C2B validation responses.
public enum C2BValidationResultCode: String {
    /// Accept the transaction.
    case accepted = "0"
    /// Invalid MSISDN (phone number).
    case invalidMSISDN = "C2B00011"
    /// Invalid account number.
    case invalidAccountNumber = "C2B00012"
    /// Invalid amount.
    case invalidAmount = "C2B00013"
    /// Invalid KYC details.
    case invalidKYCDetails = "C2B00014"
    /// Invalid short code.
    case invalidShortCode = "C2B00015"
    /// Other error.
    case otherError = "C2B00016"
}
