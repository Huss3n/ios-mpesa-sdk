//
//  B2CTypes.swift
//  MpesaSDK
//
//  Created by Muktar Aisak on 29/3/2026.
//

import Foundation

// MARK: - Command ID

/// Defines the type of B2C transaction.
public enum B2CCommandID: String, Encodable, Sendable {
    /// Supports sending money to both registered and unregistered M-PESA customers.
    case salaryPayment = "SalaryPayment"
    /// Normal business to customer payment. Supports only M-PESA registered customers.
    case businessPayment = "BusinessPayment"
    /// Promotional payment to customers with a congratulatory notification message.
    /// Supports only M-PESA registered customers.
    case promotionPayment = "PromotionPayment"
}

// MARK: - Result Code

/// Result codes returned in B2C callbacks.
public enum B2CResultCode: Int, Sendable {
    /// Transaction completed successfully.
    case success = 0
    /// Insufficient balance in the B2C utility account.
    case insufficientBalance = 1
    /// Amount is below the minimum allowed B2C transaction amount.
    case belowMinimumAmount = 2
    /// Amount exceeds the maximum allowed B2C transaction amount.
    case exceedsMaxAmount = 3
    /// Amount exceeds the daily transfer limit.
    case exceedsDailyLimit = 4
    /// Transaction would exceed the maximum customer account balance.
    case exceedsMaxBalance = 8
    /// The B2C account is not active.
    case debitPartyInvalidState = 11
    /// The API user has no ORG B2C API initiator role.
    case initiatorNotAllowed = 21
    /// The API user credentials are invalid.
    case invalidInitiatorInfo = 2001
    /// The B2C account status does not allow this transaction.
    case accountStatusNotAllowed = 2006
    /// The shortcode has no permission to perform B2C payments.
    case notPermittedByProductAssignment = 2028
    /// The customer is not registered on M-PESA.
    case customerTypeNotSupported = 2040
    /// The API user password is locked.
    case securityCredentialLocked = 8006
}
