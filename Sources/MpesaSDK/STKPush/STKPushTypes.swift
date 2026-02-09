//
//  STKPushTypes.swift
//  MpesaSDK
//
//  Created by Muktar Aisak on 10/2/2026.
//

import Foundation

// MARK: - Transaction Type

/// The type of STK Push transaction.
public enum STKPushTransactionType: String, Encodable {
    /// Payment to a paybill number.
    case customerPayBillOnline = "CustomerPayBillOnline"
    /// Payment to a till number (Buy Goods).
    case customerBuyGoodsOnline = "CustomerBuyGoodsOnline"
}

// MARK: - Result Code

/// Common result codes returned in STK Push callbacks.
public enum STKPushResultCode: Int {
    /// Transaction completed successfully.
    case success = 0
    /// Insufficient balance in the account.
    case insufficientBalance = 1
    /// Amount is below minimum allowed.
    case belowMinimumAmount = 2
    /// Amount exceeds maximum transaction limit.
    case exceedsMaxAmount = 3
    /// Amount exceeds daily transaction limit.
    case exceedsDailyLimit = 4
    /// Duplicate request — wait 2 minutes between same amount/customer.
    case duplicateRequest = 17
    /// Transaction expired before user responded.
    case transactionExpired = 1019
    /// USSD prompt too long (AccountReference too long).
    case ussdPromptTooLong = 1025
    /// User cancelled the transaction.
    case cancelledByUser = 1032
    /// Phone is unreachable.
    case phoneUnreachable = 1037
    /// User entered wrong PIN.
    case wrongPin = 2001
    /// Wrong TransactionType or PartyB mismatch.
    case wrongTransactionType = 2028
}
