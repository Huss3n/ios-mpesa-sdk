//
//  STKPushCallback.swift
//  MpesaSDK
//
//  Created by Muktar Aisak on 10/2/2026.
//

import Foundation

/// Callback payload received from M-Pesa for STK Push transactions.
///
/// The callback has a nested structure:
/// `Body` → `stkCallback` → optional `CallbackMetadata` → `Item[]`
public struct STKPushCallback: Decodable {
    /// The merchant request identifier.
    public let merchantRequestID: String

    /// The checkout request identifier.
    public let checkoutRequestID: String

    /// Result code. 0 indicates success.
    public let resultCode: Int

    /// Description of the result.
    public let resultDesc: String

    /// Metadata items present only on successful transactions.
    public let callbackMetadata: [CallbackItem]?

    /// Whether the transaction completed successfully.
    public var isSuccessful: Bool {
        resultCode == 0
    }

    /// The STK Push result code enum, if it matches a known code.
    public var resultCodeEnum: STKPushResultCode? {
        STKPushResultCode(rawValue: resultCode)
    }

    // MARK: - Computed Helpers

    /// The transaction amount (from callback metadata).
    public var amount: Double? {
        callbackMetadata?.first { $0.name == "Amount" }?.doubleValue
    }

    /// The M-Pesa receipt number (from callback metadata).
    public var mpesaReceiptNumber: String? {
        callbackMetadata?.first { $0.name == "MpesaReceiptNumber" }?.stringValue
    }

    /// The transaction date as an integer timestamp (from callback metadata).
    public var transactionDate: Int? {
        callbackMetadata?.first { $0.name == "TransactionDate" }?.intValue
    }

    /// The phone number that made the payment (from callback metadata).
    public var phoneNumber: Int? {
        callbackMetadata?.first { $0.name == "PhoneNumber" }?.intValue
    }

    // MARK: - Nested Types

    /// A single metadata item from the callback.
    public struct CallbackItem: Decodable {
        /// The metadata field name.
        public let name: String

        /// The metadata value (can be String, Int, or Double).
        public let value: AnyCodableValue?

        /// The value as a String, if applicable.
        public var stringValue: String? {
            value?.stringValue
        }

        /// The value as an Int, if applicable.
        public var intValue: Int? {
            value?.intValue
        }

        /// The value as a Double, if applicable.
        public var doubleValue: Double? {
            value?.doubleValue
        }

        enum CodingKeys: String, CodingKey {
            case name = "Name"
            case value = "Value"
        }
    }

    // MARK: - Decoding (Nested Structure)

    enum BodyKeys: String, CodingKey {
        case body = "Body"
    }

    enum STKCallbackKeys: String, CodingKey {
        case stkCallback
    }

    enum CallbackKeys: String, CodingKey {
        case merchantRequestID = "MerchantRequestID"
        case checkoutRequestID = "CheckoutRequestID"
        case resultCode = "ResultCode"
        case resultDesc = "ResultDesc"
        case callbackMetadata = "CallbackMetadata"
    }

    enum MetadataKeys: String, CodingKey {
        case item = "Item"
    }

    public init(from decoder: Decoder) throws {
        let body = try decoder.container(keyedBy: BodyKeys.self)
        let stkContainer = try body.nestedContainer(keyedBy: STKCallbackKeys.self, forKey: .body)
        let callback = try stkContainer.nestedContainer(
            keyedBy: CallbackKeys.self,
            forKey: .stkCallback
        )

        merchantRequestID = try callback.decode(String.self, forKey: .merchantRequestID)
        checkoutRequestID = try callback.decode(String.self, forKey: .checkoutRequestID)
        resultCode = try callback.decode(Int.self, forKey: .resultCode)
        resultDesc = try callback.decode(String.self, forKey: .resultDesc)

        if let metadataContainer = try? callback.nestedContainer(
            keyedBy: MetadataKeys.self,
            forKey: .callbackMetadata
        ) {
            callbackMetadata = try metadataContainer.decode(
                [CallbackItem].self,
                forKey: .item
            )
        } else {
            callbackMetadata = nil
        }
    }

    init(
        merchantRequestID: String,
        checkoutRequestID: String,
        resultCode: Int,
        resultDesc: String,
        callbackMetadata: [CallbackItem]?
    ) {
        self.merchantRequestID = merchantRequestID
        self.checkoutRequestID = checkoutRequestID
        self.resultCode = resultCode
        self.resultDesc = resultDesc
        self.callbackMetadata = callbackMetadata
    }
}
