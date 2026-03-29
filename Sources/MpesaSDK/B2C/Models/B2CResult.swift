//
//  B2CResult.swift
//  MpesaSDK
//
//  Created by Muktar Aisak on 29/3/2026.
//

import Foundation

/// Async result callback from the B2C API.
///
/// This payload arrives at the `ResultURL` after M-Pesa processes the transaction.
/// On success, `ResultParameters` contains transaction details as key-value pairs.
/// On failure, `ResultParameters` may be absent or a single object instead of an array.
public struct B2CResult: Decodable, Sendable {
    /// Result code. 0 indicates success.
    public let resultCode: Int

    /// Description of the result.
    public let resultDesc: String

    /// Unique identifier for the originator's conversation.
    public let originatorConversationID: String

    /// Unique identifier for the conversation.
    public let conversationID: String

    /// Unique M-Pesa transaction ID.
    public let transactionID: String

    /// Result parameters containing transaction details.
    public let resultParameters: [ResultParameter]?

    /// Reference data items.
    public let referenceData: [ReferenceItem]?

    /// Whether the transaction completed successfully.
    public var isSuccessful: Bool {
        resultCode == 0
    }

    /// The typed result code, if it matches a known B2C result code.
    public var resultCodeEnum: B2CResultCode? {
        B2CResultCode(rawValue: resultCode)
    }

    // MARK: - Computed Helpers

    /// The transaction amount.
    public var transactionAmount: Double? {
        resultParameters?.first { $0.key == "TransactionAmount" }?.value?.doubleValue
    }

    /// The M-Pesa transaction receipt ID.
    public var transactionReceipt: String? {
        resultParameters?.first {
            $0.key == "TransactionReceipt"
        }?.value?.stringValue
    }

    /// The receiver's name and phone number.
    public var receiverPartyPublicName: String? {
        resultParameters?.first {
            $0.key == "ReceiverPartyPublicName"
        }?.value?.stringValue
    }

    /// The date and time the transaction completed.
    public var transactionCompletedDateTime: String? {
        resultParameters?.first {
            $0.key == "TransactionCompletedDateTime"
        }?.value?.stringValue
    }

    /// Available balance of the B2C utility account.
    public var b2cUtilityAccountAvailableFunds: Double? {
        resultParameters?.first {
            $0.key == "B2CUtilityAccountAvailableFunds"
        }?.value?.doubleValue
    }

    /// Available balance of the B2C working account.
    public var b2cWorkingAccountAvailableFunds: Double? {
        resultParameters?.first {
            $0.key == "B2CWorkingAccountAvailableFunds"
        }?.value?.doubleValue
    }

    /// Whether the recipient is a registered M-PESA customer ("Y" or "N").
    public var b2cRecipientIsRegisteredCustomer: String? {
        resultParameters?.first {
            $0.key == "B2CRecipientIsRegisteredCustomer"
        }?.value?.stringValue
    }

    /// Available balance of the charges paid account.
    public var b2cChargesPaidAccountAvailableFunds: Double? {
        resultParameters?.first {
            $0.key == "B2CChargesPaidAccountAvailableFunds"
        }?.value?.doubleValue
    }

    // MARK: - Reference Item

    /// A reference data item from the result callback.
    public struct ReferenceItem: Decodable, Sendable {
        /// The reference key.
        public let key: String

        /// The reference value. Optional — some items have no value.
        public let value: String?

        enum CodingKeys: String, CodingKey {
            case key = "Key"
            case value = "Value"
        }
    }

    // MARK: - Decoding

    enum TopLevelKeys: String, CodingKey {
        case result = "Result"
    }

    enum ResultKeys: String, CodingKey {
        case resultType = "ResultType"
        case resultCode = "ResultCode"
        case resultDesc = "ResultDesc"
        case originatorConversationID = "OriginatorConversationID"
        case conversationID = "ConversationID"
        case transactionID = "TransactionID"
        case resultParameters = "ResultParameters"
        case referenceData = "ReferenceData"
    }

    enum ParameterContainerKeys: String, CodingKey {
        case resultParameter = "ResultParameter"
    }

    enum ReferenceContainerKeys: String, CodingKey {
        case referenceItem = "ReferenceItem"
    }

    public init(from decoder: Decoder) throws {
        let topLevel = try decoder.container(keyedBy: TopLevelKeys.self)
        let result = try topLevel.nestedContainer(
            keyedBy: ResultKeys.self,
            forKey: .result
        )

        // ResultCode can be Int or String
        if let intCode = try? result.decode(Int.self, forKey: .resultCode) {
            resultCode = intCode
        } else {
            let stringCode = try result.decode(String.self, forKey: .resultCode)
            resultCode = Int(stringCode) ?? -1
        }

        resultDesc = try result.decode(String.self, forKey: .resultDesc)
        originatorConversationID = try result.decode(
            String.self,
            forKey: .originatorConversationID
        )
        conversationID = try result.decode(String.self, forKey: .conversationID)
        transactionID = try result.decode(String.self, forKey: .transactionID)

        resultParameters = Self.decodeParameters(from: result)
        referenceData = Self.decodeReferenceData(from: result)
    }

    private static func decodeParameters(
        from container: KeyedDecodingContainer<ResultKeys>
    ) -> [ResultParameter]? {
        guard let nested = try? container.nestedContainer(
            keyedBy: ParameterContainerKeys.self,
            forKey: .resultParameters
        ) else { return nil }

        if let params = try? nested.decode([ResultParameter].self, forKey: .resultParameter) {
            return params
        } else if let param = try? nested.decode(ResultParameter.self, forKey: .resultParameter) {
            return [param]
        }
        return nil
    }

    private static func decodeReferenceData(
        from container: KeyedDecodingContainer<ResultKeys>
    ) -> [ReferenceItem]? {
        guard let nested = try? container.nestedContainer(
            keyedBy: ReferenceContainerKeys.self,
            forKey: .referenceData
        ) else { return nil }

        if let items = try? nested.decode([ReferenceItem].self, forKey: .referenceItem) {
            return items
        } else if let item = try? nested.decode(ReferenceItem.self, forKey: .referenceItem) {
            return [item]
        }
        return nil
    }

    init(
        resultCode: Int,
        resultDesc: String,
        originatorConversationID: String,
        conversationID: String,
        transactionID: String,
        resultParameters: [ResultParameter]?,
        referenceData: [ReferenceItem]?
    ) {
        self.resultCode = resultCode
        self.resultDesc = resultDesc
        self.originatorConversationID = originatorConversationID
        self.conversationID = conversationID
        self.transactionID = transactionID
        self.resultParameters = resultParameters
        self.referenceData = referenceData
    }
}
