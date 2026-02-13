//
//  B2CTopUpTests.swift
//  MpesaSDK
//
//  Created by Muktar Aisak on 12/2/2026.
//

import XCTest
@testable import MpesaSDK

final class B2CTopUpTests: XCTestCase {

    // MARK: - B2CTopUpRequest Encoding Tests

    func testRequestEncoding() throws {
        let request = B2CTopUpRequest(
            initiator: "testInitiator",
            securityCredential: "encryptedCred123",
            partyA: "600984",
            partyB: "600000",
            amount: 239,
            accountReference: "353353",
            resultURL: URL(string: "https://example.com/result")!,
            queueTimeOutURL: URL(string: "https://example.com/timeout")!
        )

        let data = try JSONEncoder().encode(request)
        // swiftlint:disable:next force_cast
        let json = try JSONSerialization.jsonObject(with: data) as! [String: Any]

        XCTAssertEqual(json["Initiator"] as? String, "testInitiator")
        XCTAssertEqual(json["SecurityCredential"] as? String, "encryptedCred123")
        XCTAssertEqual(json["CommandID"] as? String, "BusinessPayToBulk")
        XCTAssertEqual(json["SenderIdentifierType"] as? String, "4")
        XCTAssertEqual(json["RecieverIdentifierType"] as? String, "4")
        XCTAssertEqual(json["Amount"] as? String, "239")
        XCTAssertEqual(json["PartyA"] as? String, "600984")
        XCTAssertEqual(json["PartyB"] as? String, "600000")
        XCTAssertEqual(json["AccountReference"] as? String, "353353")
        XCTAssertEqual(json["Remarks"] as? String, "OK")
        XCTAssertEqual(
            json["ResultURL"] as? String,
            "https://example.com/result"
        )
        XCTAssertEqual(
            json["QueueTimeOutURL"] as? String,
            "https://example.com/timeout"
        )
    }

    func testRequestEncodingWithOptionalFields() throws {
        let request = B2CTopUpRequest(
            initiator: "testInitiator",
            securityCredential: "encryptedCred123",
            partyA: "600984",
            partyB: "600000",
            amount: 500,
            accountReference: "353353",
            resultURL: URL(string: "https://example.com/result")!,
            queueTimeOutURL: URL(string: "https://example.com/timeout")!,
            requester: "254722000000",
            remarks: "Top up funds"
        )

        let data = try JSONEncoder().encode(request)
        // swiftlint:disable:next force_cast
        let json = try JSONSerialization.jsonObject(with: data) as! [String: Any]

        XCTAssertEqual(json["Requester"] as? String, "254722000000")
        XCTAssertEqual(json["Remarks"] as? String, "Top up funds")
    }

    func testRequestAmountEncodedAsString() throws {
        let request = B2CTopUpRequest(
            initiator: "testInitiator",
            securityCredential: "cred",
            partyA: "600984",
            partyB: "600000",
            amount: 1000,
            accountReference: "ref",
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

    func testRequestFixedFieldsAlwaysPresent() throws {
        let request = B2CTopUpRequest(
            initiator: "init",
            securityCredential: "cred",
            partyA: "600984",
            partyB: "600000",
            amount: 1,
            accountReference: "ref",
            resultURL: URL(string: "https://example.com/result")!,
            queueTimeOutURL: URL(string: "https://example.com/timeout")!
        )

        let data = try JSONEncoder().encode(request)
        // swiftlint:disable:next force_cast
        let json = try JSONSerialization.jsonObject(with: data) as! [String: Any]

        XCTAssertEqual(json["CommandID"] as? String, "BusinessPayToBulk")
        XCTAssertEqual(json["SenderIdentifierType"] as? String, "4")
        XCTAssertEqual(json["RecieverIdentifierType"] as? String, "4")
    }

    // MARK: - B2CTopUpResponse Decoding Tests

    func testResponseDecoding() throws {
        let json = """
        {
            "OriginatorConversationID": "2dfa-bda3-4f3f-bb89-c62e4133280d71011",
            "ConversationID": "AG_20240710_2010325b025970fbc403",
            "ResponseCode": "0",
            "ResponseDescription": "Accept the service request successfully."
        }
        """.data(using: .utf8)!

        let response = try JSONDecoder().decode(B2CTopUpResponse.self, from: json)

        XCTAssertEqual(
            response.originatorConversationID,
            "2dfa-bda3-4f3f-bb89-c62e4133280d71011"
        )
        XCTAssertEqual(
            response.conversationID,
            "AG_20240710_2010325b025970fbc403"
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

        let response = try JSONDecoder().decode(B2CTopUpResponse.self, from: json)
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

        let response = try JSONDecoder().decode(B2CTopUpResponse.self, from: json)
        XCTAssertTrue(response.isSuccessful)
    }

    // MARK: - B2CTopUpResult Decoding Tests

    func testSuccessResultDecoding() throws {
        let json = """
        {
            "Result": {
                "ResultType": 0,
                "ResultCode": 0,
                "ResultDesc": "The service request is processed successfully.",
                "OriginatorConversationID": "2dfa-bb89-c62e4133280d71011",
                "ConversationID": "AG_20240710_2010325b025970fbc403",
                "TransactionID": "SBL2G50CB3",
                "ResultParameters": {
                    "ResultParameter": [
                        { "Key": "DebitPartyName", "Value": "600984 - Safcom" },
                        { "Key": "CreditPartyName", "Value": "600000 - Safcom" },
                        { "Key": "Amount", "Value": 239 },
                        { "Key": "DebitPartyCharges", "Value": "Fee For B2C Payment|KES|2.63" },
                        { "Key": "TransCompletedTime", "Value": "20240710101835" },
                        { "Key": "TransactionReceipt", "Value": "SBL2G50CB3" },
                        { "Key": "Currency", "Value": "KES" }
                    ]
                },
                "ReferenceData": {
                    "ReferenceItem": [
                        { "Key": "QueueTimeoutURL", "Value": "https://example.com/timeout" },
                        { "Key": "Occasion" }
                    ]
                }
            }
        }
        """.data(using: .utf8)!

        let result = try JSONDecoder().decode(B2CTopUpResult.self, from: json)

        XCTAssertEqual(result.resultCode, 0)
        XCTAssertTrue(result.isSuccessful)
        XCTAssertEqual(result.transactionID, "SBL2G50CB3")
        XCTAssertEqual(
            result.originatorConversationID,
            "2dfa-bb89-c62e4133280d71011"
        )
        XCTAssertEqual(result.amount, 239.0)
        XCTAssertEqual(result.transactionReceipt, "SBL2G50CB3")
        XCTAssertEqual(result.transCompletedTime, "20240710101835")
        XCTAssertEqual(result.currency, "KES")
        XCTAssertEqual(
            result.debitPartyCharges,
            "Fee For B2C Payment|KES|2.63"
        )
        XCTAssertNotNil(result.referenceData)
        XCTAssertEqual(result.referenceData?.count, 2)
        XCTAssertNil(result.referenceData?.last?.value)
    }

    func testFailureResultDecoding() throws {
        let json = """
        {
            "Result": {
                "ResultType": 0,
                "ResultCode": 2001,
                "ResultDesc": "The initiator information is invalid.",
                "OriginatorConversationID": "fail-orig-id",
                "ConversationID": "AG_fail",
                "TransactionID": "SBL0000000",
                "ReferenceData": {
                    "ReferenceItem": {
                        "Key": "QueueTimeoutURL",
                        "Value": "https://example.com/timeout"
                    }
                }
            }
        }
        """.data(using: .utf8)!

        let result = try JSONDecoder().decode(B2CTopUpResult.self, from: json)

        XCTAssertEqual(result.resultCode, 2001)
        XCTAssertFalse(result.isSuccessful)
        XCTAssertNil(result.resultParameters)
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
                        { "Key": "Amount", "Value": 100 }
                    ]
                }
            }
        }
        """.data(using: .utf8)!

        let result = try JSONDecoder().decode(B2CTopUpResult.self, from: json)

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

        let result = try JSONDecoder().decode(B2CTopUpResult.self, from: json)

        XCTAssertEqual(result.resultCode, 500)
        XCTAssertFalse(result.isSuccessful)
        XCTAssertEqual(result.resultParameters?.count, 1)
        XCTAssertEqual(result.resultParameters?.first?.key, "ErrorMessage")
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
                "TransactionID": "SBL333",
                "ResultParameters": {
                    "ResultParameter": [
                        { "Key": "Amount", "Value": 500.00 },
                        { "Key": "Currency", "Value": "KES" }
                    ]
                }
            }
        }
        """.data(using: .utf8)!

        let result = try B2CTopUpService.parseResult(from: json)
        XCTAssertTrue(result.isSuccessful)
        XCTAssertEqual(result.amount, 500.0)
        XCTAssertEqual(result.currency, "KES")
    }

    func testParseResultInvalidJSON() {
        let invalidData = "not json".data(using: .utf8)!

        XCTAssertThrowsError(
            try B2CTopUpService.parseResult(from: invalidData)
        ) { error in
            XCTAssertTrue(error is MpesaError)
        }
    }
}
