//
//  B2CTests.swift
//  MpesaSDK
//
//  Created by Muktar Aisak on 29/3/2026.
//

import XCTest
@testable import MpesaSDK

final class B2CTests: XCTestCase {

    // MARK: - B2CRequest Encoding Tests

    func testRequestEncoding() throws {
        let request = B2CRequest(
            originatorConversationID: "600997_Test_32et3241ed8yu",
            initiatorName: "testapi",
            securityCredential: "RC6E9WDxXR4b9X2c6z3gp0oC5Th==",
            commandID: .businessPayment,
            amount: 10,
            partyA: "600992",
            partyB: "254705912645",
            remarks: "remarked",
            resultURL: URL(string: "https://example.com/result")!,
            queueTimeOutURL: URL(string: "https://example.com/timeout")!,
            occasion: "ChristmasPay"
        )

        let data = try JSONEncoder().encode(request)
        // swiftlint:disable:next force_cast
        let json = try JSONSerialization.jsonObject(with: data) as! [String: Any]

        XCTAssertEqual(
            json["OriginatorConversationID"] as? String,
            "600997_Test_32et3241ed8yu"
        )
        XCTAssertEqual(json["InitiatorName"] as? String, "testapi")
        XCTAssertEqual(
            json["SecurityCredential"] as? String,
            "RC6E9WDxXR4b9X2c6z3gp0oC5Th=="
        )
        XCTAssertEqual(json["CommandID"] as? String, "BusinessPayment")
        XCTAssertEqual(json["Amount"] as? String, "10")
        XCTAssertEqual(json["PartyA"] as? String, "600992")
        XCTAssertEqual(json["PartyB"] as? String, "254705912645")
        XCTAssertEqual(json["Remarks"] as? String, "remarked")
        XCTAssertEqual(
            json["ResultURL"] as? String,
            "https://example.com/result"
        )
        XCTAssertEqual(
            json["QueueTimeOutURL"] as? String,
            "https://example.com/timeout"
        )
        XCTAssertEqual(json["Occassion"] as? String, "ChristmasPay")
    }

    func testRequestEncodingWithoutOccasion() throws {
        let request = B2CRequest(
            originatorConversationID: "test-id",
            initiatorName: "testapi",
            securityCredential: "cred",
            amount: 100,
            partyA: "600992",
            partyB: "254705912645",
            resultURL: URL(string: "https://example.com/result")!,
            queueTimeOutURL: URL(string: "https://example.com/timeout")!
        )

        let data = try JSONEncoder().encode(request)
        // swiftlint:disable:next force_cast
        let json = try JSONSerialization.jsonObject(with: data) as! [String: Any]

        XCTAssertNil(json["Occassion"])
        XCTAssertEqual(json["Remarks"] as? String, "OK")
        XCTAssertEqual(json["CommandID"] as? String, "BusinessPayment")
    }

    func testRequestAmountEncodedAsString() throws {
        let request = B2CRequest(
            originatorConversationID: "test-id",
            initiatorName: "testapi",
            securityCredential: "cred",
            amount: 1000,
            partyA: "600992",
            partyB: "254705912645",
            resultURL: URL(string: "https://example.com/result")!,
            queueTimeOutURL: URL(string: "https://example.com/timeout")!
        )

        let data = try JSONEncoder().encode(request)
        // swiftlint:disable:next force_cast
        let json = try JSONSerialization.jsonObject(with: data) as! [String: Any]

        // Amount must be a String, not an Int
        XCTAssertEqual(json["Amount"] as? String, "1000")
        XCTAssertNil(json["Amount"] as? Int)
    }

    func testRequestCommandIDVariants() throws {
        let salaryRequest = B2CRequest(
            originatorConversationID: "salary-id",
            initiatorName: "testapi",
            securityCredential: "cred",
            commandID: .salaryPayment,
            amount: 50000,
            partyA: "600992",
            partyB: "254705912645",
            resultURL: URL(string: "https://example.com/result")!,
            queueTimeOutURL: URL(string: "https://example.com/timeout")!
        )

        let promoRequest = B2CRequest(
            originatorConversationID: "promo-id",
            initiatorName: "testapi",
            securityCredential: "cred",
            commandID: .promotionPayment,
            amount: 500,
            partyA: "600992",
            partyB: "254705912645",
            resultURL: URL(string: "https://example.com/result")!,
            queueTimeOutURL: URL(string: "https://example.com/timeout")!
        )

        let salaryData = try JSONEncoder().encode(salaryRequest)
        // swiftlint:disable:next force_cast
        let salaryJSON = try JSONSerialization.jsonObject(with: salaryData) as! [String: Any]
        XCTAssertEqual(salaryJSON["CommandID"] as? String, "SalaryPayment")

        let promoData = try JSONEncoder().encode(promoRequest)
        // swiftlint:disable:next force_cast
        let promoJSON = try JSONSerialization.jsonObject(with: promoData) as! [String: Any]
        XCTAssertEqual(promoJSON["CommandID"] as? String, "PromotionPayment")
    }

    // MARK: - B2CResponse Decoding Tests

    func testResponseDecoding() throws {
        let json = """
        {
            "ConversationID": "AG_20240706_20106e9209f64bebd05b",
            "OriginatorConversationID": "600997_Test_32et3241ed8yu",
            "ResponseCode": "0",
            "ResponseDescription": "Accept the service request successfully."
        }
        """.data(using: .utf8)!

        let response = try JSONDecoder().decode(B2CResponse.self, from: json)

        XCTAssertEqual(
            response.originatorConversationID,
            "600997_Test_32et3241ed8yu"
        )
        XCTAssertEqual(
            response.conversationID,
            "AG_20240706_20106e9209f64bebd05b"
        )
        XCTAssertEqual(response.responseCode, "0")
        XCTAssertTrue(response.isSuccessful)
    }

    func testResponseDecodingFailure() throws {
        let json = """
        {
            "OriginatorConversationID": "fail-id",
            "ConversationID": "AG_fail",
            "ResponseCode": "1",
            "ResponseDescription": "Rejected"
        }
        """.data(using: .utf8)!

        let response = try JSONDecoder().decode(B2CResponse.self, from: json)
        XCTAssertFalse(response.isSuccessful)
    }

    func testResponseWithSandboxCode() throws {
        let json = """
        {
            "OriginatorConversationID": "sandbox-id",
            "ConversationID": "AG_sandbox",
            "ResponseCode": "00000000",
            "ResponseDescription": "Success"
        }
        """.data(using: .utf8)!

        let response = try JSONDecoder().decode(B2CResponse.self, from: json)
        XCTAssertTrue(response.isSuccessful)
    }

    // MARK: - B2CResult Decoding Tests

    func testSuccessResultDecoding() throws {
        let json = """
        {
            "Result": {
                "ResultType": 0,
                "ResultCode": 0,
                "ResultDesc": "The service request is processed successfully.",
                "OriginatorConversationID": "53e3-4aa8-9fe0-8fb5e4092cdd3533373",
                "ConversationID": "AG_20240706_2010364430d9bbdaf872",
                "TransactionID": "SG632NMUAB",
                "ResultParameters": {
                    "ResultParameter": [
                        { "Key": "TransactionAmount", "Value": 10 },
                        { "Key": "TransactionReceipt", "Value": "SG632NMUAB" },
                        { "Key": "ReceiverPartyPublicName", "Value": "254705912645 - NICHOLAS JOHN SONGOK" },
                        { "Key": "TransactionCompletedDateTime", "Value": "06.07.2024 22:48:52" },
                        { "Key": "B2CUtilityAccountAvailableFunds", "Value": 8959269.60 },
                        { "Key": "B2CWorkingAccountAvailableFunds", "Value": 1199371.00 },
                        { "Key": "B2CRecipientIsRegisteredCustomer", "Value": "Y" },
                        { "Key": "B2CChargesPaidAccountAvailableFunds", "Value": -1980.00 }
                    ]
                },
                "ReferenceData": {
                    "ReferenceItem": {
                        "Key": "QueueTimeoutURL",
                        "Value": "https://internalsandbox.safaricom.co.ke/mpesa/b2cresults/v1/submit"
                    }
                }
            }
        }
        """.data(using: .utf8)!

        let result = try JSONDecoder().decode(B2CResult.self, from: json)

        XCTAssertEqual(result.resultCode, 0)
        XCTAssertTrue(result.isSuccessful)
        XCTAssertEqual(result.resultCodeEnum, .success)
        XCTAssertEqual(result.transactionID, "SG632NMUAB")
        XCTAssertEqual(
            result.originatorConversationID,
            "53e3-4aa8-9fe0-8fb5e4092cdd3533373"
        )
        XCTAssertEqual(result.transactionAmount, 10.0)
        XCTAssertEqual(result.transactionReceipt, "SG632NMUAB")
        XCTAssertEqual(
            result.receiverPartyPublicName,
            "254705912645 - NICHOLAS JOHN SONGOK"
        )
        XCTAssertEqual(
            result.transactionCompletedDateTime,
            "06.07.2024 22:48:52"
        )
        XCTAssertEqual(result.b2cUtilityAccountAvailableFunds, 8_959_269.60)
        XCTAssertEqual(result.b2cWorkingAccountAvailableFunds, 1_199_371.00)
        XCTAssertEqual(result.b2cRecipientIsRegisteredCustomer, "Y")
        XCTAssertEqual(result.b2cChargesPaidAccountAvailableFunds, -1980.00)
        XCTAssertNotNil(result.referenceData)
        XCTAssertEqual(result.referenceData?.count, 1)
    }

    func testFailureResultDecoding() throws {
        let json = """
        {
            "Result": {
                "ResultType": 0,
                "ResultCode": 2001,
                "ResultDesc": "The initiator information is invalid.",
                "OriginatorConversationID": "53e3-4aa8-9fe0-8fb5e4092cdd3544366",
                "ConversationID": "AG_20240707_201062f6f6f5804f7a33",
                "TransactionID": "SG722NMVXQ",
                "ReferenceData": {
                    "ReferenceItem": {
                        "Key": "QueueTimeoutURL",
                        "Value": "https://internalsandbox.safaricom.co.ke/mpesa/b2cresults/v1/submit"
                    }
                }
            }
        }
        """.data(using: .utf8)!

        let result = try JSONDecoder().decode(B2CResult.self, from: json)

        XCTAssertEqual(result.resultCode, 2001)
        XCTAssertFalse(result.isSuccessful)
        XCTAssertEqual(result.resultCodeEnum, .invalidInitiatorInfo)
        XCTAssertNil(result.resultParameters)
        XCTAssertNil(result.transactionAmount)
        XCTAssertNotNil(result.referenceData)
        XCTAssertEqual(result.referenceData?.count, 1)
    }

    func testResultWithStringResultCode() throws {
        let json = """
        {
            "Result": {
                "ResultType": 0,
                "ResultCode": "0",
                "ResultDesc": "Success.",
                "OriginatorConversationID": "str-code-id",
                "ConversationID": "AG_str",
                "TransactionID": "SBL111",
                "ResultParameters": {
                    "ResultParameter": [
                        { "Key": "TransactionAmount", "Value": 100 }
                    ]
                }
            }
        }
        """.data(using: .utf8)!

        let result = try JSONDecoder().decode(B2CResult.self, from: json)

        XCTAssertEqual(result.resultCode, 0)
        XCTAssertTrue(result.isSuccessful)
    }

    func testResultWithSingleResultParameter() throws {
        let json = """
        {
            "Result": {
                "ResultType": 0,
                "ResultCode": 500,
                "ResultDesc": "Error occurred.",
                "OriginatorConversationID": "single-param-id",
                "ConversationID": "AG_single",
                "TransactionID": "SBL222",
                "ResultParameters": {
                    "ResultParameter": {
                        "Key": "ErrorMessage",
                        "Value": "Something went wrong"
                    }
                }
            }
        }
        """.data(using: .utf8)!

        let result = try JSONDecoder().decode(B2CResult.self, from: json)

        XCTAssertEqual(result.resultCode, 500)
        XCTAssertFalse(result.isSuccessful)
        XCTAssertEqual(result.resultParameters?.count, 1)
        XCTAssertEqual(result.resultParameters?.first?.key, "ErrorMessage")
    }

    func testResultWithReferenceDataArray() throws {
        let json = """
        {
            "Result": {
                "ResultType": 0,
                "ResultCode": 0,
                "ResultDesc": "Success.",
                "OriginatorConversationID": "ref-array-id",
                "ConversationID": "AG_ref",
                "TransactionID": "SBL333",
                "ReferenceData": {
                    "ReferenceItem": [
                        { "Key": "QueueTimeoutURL", "Value": "https://example.com/timeout" },
                        { "Key": "Occasion" }
                    ]
                }
            }
        }
        """.data(using: .utf8)!

        let result = try JSONDecoder().decode(B2CResult.self, from: json)

        XCTAssertEqual(result.referenceData?.count, 2)
        XCTAssertNil(result.referenceData?.last?.value)
    }

    // MARK: - Result Code Enum

    func testResultCodeEnumMapping() {
        XCTAssertEqual(B2CResultCode(rawValue: 0), .success)
        XCTAssertEqual(B2CResultCode(rawValue: 1), .insufficientBalance)
        XCTAssertEqual(B2CResultCode(rawValue: 2), .belowMinimumAmount)
        XCTAssertEqual(B2CResultCode(rawValue: 3), .exceedsMaxAmount)
        XCTAssertEqual(B2CResultCode(rawValue: 4), .exceedsDailyLimit)
        XCTAssertEqual(B2CResultCode(rawValue: 8), .exceedsMaxBalance)
        XCTAssertEqual(B2CResultCode(rawValue: 11), .debitPartyInvalidState)
        XCTAssertEqual(B2CResultCode(rawValue: 21), .initiatorNotAllowed)
        XCTAssertEqual(B2CResultCode(rawValue: 2001), .invalidInitiatorInfo)
        XCTAssertEqual(B2CResultCode(rawValue: 2006), .accountStatusNotAllowed)
        XCTAssertEqual(
            B2CResultCode(rawValue: 2028),
            .notPermittedByProductAssignment
        )
        XCTAssertEqual(B2CResultCode(rawValue: 2040), .customerTypeNotSupported)
        XCTAssertEqual(B2CResultCode(rawValue: 8006), .securityCredentialLocked)
        XCTAssertNil(B2CResultCode(rawValue: 9999))
    }

    // MARK: - Parse via Service

    func testParseResultViaService() throws {
        let json = """
        {
            "Result": {
                "ResultType": 0,
                "ResultCode": 0,
                "ResultDesc": "Processed successfully.",
                "OriginatorConversationID": "parse-id",
                "ConversationID": "AG_parse",
                "TransactionID": "SBL444",
                "ResultParameters": {
                    "ResultParameter": [
                        { "Key": "TransactionAmount", "Value": 500 },
                        { "Key": "TransactionReceipt", "Value": "SBL444" },
                        { "Key": "B2CRecipientIsRegisteredCustomer", "Value": "Y" }
                    ]
                }
            }
        }
        """.data(using: .utf8)!

        let result = try B2CService.parseResult(from: json)
        XCTAssertTrue(result.isSuccessful)
        XCTAssertEqual(result.transactionAmount, 500.0)
        XCTAssertEqual(result.transactionReceipt, "SBL444")
        XCTAssertEqual(result.b2cRecipientIsRegisteredCustomer, "Y")
    }

    func testParseResultInvalidJSON() {
        let invalidData = "not json".data(using: .utf8)!

        XCTAssertThrowsError(
            try B2CService.parseResult(from: invalidData)
        ) { error in
            XCTAssertTrue(error is MpesaError)
        }
    }
}
