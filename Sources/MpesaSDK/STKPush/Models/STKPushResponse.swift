//
//  STKPushResponse.swift
//  MpesaSDK
//
//  Created by Muktar Aisak on 10/2/2026.
//

import Foundation

/// Response from the STK Push (Lipa Na M-Pesa) API.
public struct STKPushResponse: Decodable {
    /// Unique identifier for the merchant request.
    public let merchantRequestID: String

    /// Unique identifier for the checkout request. Use this to track the transaction.
    public let checkoutRequestID: String

    /// Response code. "0" indicates the request was accepted for processing.
    public let responseCode: String

    /// Description of the response status.
    public let responseDescription: String

    /// Customer-facing message from M-Pesa.
    public let customerMessage: String

    /// Whether the STK Push request was accepted for processing.
    public var isSuccessful: Bool {
        Int(responseCode) == 0
    }

    init(
        merchantRequestID: String,
        checkoutRequestID: String,
        responseCode: String,
        responseDescription: String,
        customerMessage: String
    ) {
        self.merchantRequestID = merchantRequestID
        self.checkoutRequestID = checkoutRequestID
        self.responseCode = responseCode
        self.responseDescription = responseDescription
        self.customerMessage = customerMessage
    }

    enum CodingKeys: String, CodingKey {
        case merchantRequestID = "MerchantRequestID"
        case checkoutRequestID = "CheckoutRequestID"
        case responseCode = "ResponseCode"
        case responseDescription = "ResponseDescription"
        case customerMessage = "CustomerMessage"
    }
}
