//
//  STKPushTests.swift
//  MpesaSDK
//
//  Created by Muktar Aisak on 10/2/2026.
//

import XCTest
@testable import MpesaSDK

final class STKPushTests: XCTestCase {

    // MARK: - STKPushRequest Tests

    func testRequestEncoding() throws {
        let request = STKPushRequest(
            businessShortCode: "174379",
            passKey: "testPassKey123",
            amount: 1,
            phoneNumber: "254722000000",
            callbackURL: URL(string: "https://example.com/callback")!,
            accountReference: "TestRef",
            transactionDesc: "Test Payment"
        )

        let data = try JSONEncoder().encode(request)
        // swiftlint:disable:next force_cast
        let json = try JSONSerialization.jsonObject(with: data) as! [String: Any]

        XCTAssertEqual(json["BusinessShortCode"] as? Int, 174379)
        XCTAssertEqual(json["TransactionType"] as? String, "CustomerPayBillOnline")
        XCTAssertEqual(json["Amount"] as? Int, 1)
        XCTAssertEqual(json["PartyA"] as? Int, 254722000000)
        XCTAssertEqual(json["PartyB"] as? Int, 174379)
        XCTAssertEqual(json["PhoneNumber"] as? Int, 254722000000)
        XCTAssertEqual(json["CallBackURL"] as? String, "https://example.com/callback")
        XCTAssertEqual(json["AccountReference"] as? String, "TestRef")
        XCTAssertEqual(json["TransactionDesc"] as? String, "Test Payment")
        XCTAssertNotNil(json["Password"] as? String)
        XCTAssertNotNil(json["Timestamp"] as? String)
    }

    func testRequestBuyGoodsEncoding() throws {
        let request = STKPushRequest(
            businessShortCode: "174379",
            passKey: "testPassKey123",
            amount: 50,
            phoneNumber: "254722000000",
            callbackURL: URL(string: "https://example.com/callback")!,
            accountReference: "TestRef",
            transactionDesc: "Buy Goods",
            transactionType: .customerBuyGoodsOnline
        )

        let data = try JSONEncoder().encode(request)
        // swiftlint:disable:next force_cast
        let json = try JSONSerialization.jsonObject(with: data) as! [String: Any]

        XCTAssertEqual(json["TransactionType"] as? String, "CustomerBuyGoodsOnline")
    }

    // MARK: - Password Generation Tests

    func testPasswordGeneration() {
        let password = STKPushRequest.generatePassword(
            businessShortCode: "174379",
            passKey: "bfb279f9aa9bdbcf158e97dd71a467cd2e0c893059b10f78e6b72ada1ed2c919",
            timestamp: "20210628092408"
        )

        // base64("174379" + passkey + "20210628092408")
        let expected = Data(
            ("174379"
                + "bfb279f9aa9bdbcf158e97dd71a467cd2e0c893059b10f78e6b72ada1ed2c919"
                + "20210628092408").utf8
        ).base64EncodedString()

        XCTAssertEqual(password, expected)
    }

    func testTimestampFormat() {
        let timestamp = STKPushRequest.generateTimestamp()

        // Timestamp should be 14 characters: YYYYMMDDHHmmss
        XCTAssertEqual(timestamp.count, 14)
        XCTAssertNotNil(Int(timestamp))
    }

    func testTimestampFromKnownDate() {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "Africa/Nairobi")!
        let components = DateComponents(
            year: 2024, month: 7, day: 10,
            hour: 9, minute: 15, second: 26
        )
        let date = calendar.date(from: components)!

        let timestamp = STKPushRequest.generateTimestamp(from: date)
        XCTAssertEqual(timestamp, "20240710091526")
    }

    // MARK: - Transaction Type Tests

    func testTransactionTypeValues() {
        XCTAssertEqual(
            STKPushTransactionType.customerPayBillOnline.rawValue,
            "CustomerPayBillOnline"
        )
        XCTAssertEqual(
            STKPushTransactionType.customerBuyGoodsOnline.rawValue,
            "CustomerBuyGoodsOnline"
        )
    }

    // MARK: - STKPushResponse Tests

    func testResponseDecoding() throws {
        let json = """
        {
            "MerchantRequestID": "2654-4b64-97ff-b827b542881d3130",
            "CheckoutRequestID": "ws_CO_1007202409152617172396192",
            "ResponseCode": "0",
            "ResponseDescription": "Success. Request accepted for processing",
            "CustomerMessage": "Success. Request accepted for processing"
        }
        """.data(using: .utf8)!

        let response = try JSONDecoder().decode(STKPushResponse.self, from: json)

        XCTAssertEqual(response.merchantRequestID, "2654-4b64-97ff-b827b542881d3130")
        XCTAssertEqual(response.checkoutRequestID, "ws_CO_1007202409152617172396192")
        XCTAssertEqual(response.responseCode, "0")
        XCTAssertTrue(response.isSuccessful)
        XCTAssertEqual(
            response.customerMessage,
            "Success. Request accepted for processing"
        )
    }

    func testResponseWithSandboxCode() throws {
        let json = """
        {
            "MerchantRequestID": "sandbox-id",
            "CheckoutRequestID": "ws_CO_sandbox",
            "ResponseCode": "00000000",
            "ResponseDescription": "Success",
            "CustomerMessage": "Success"
        }
        """.data(using: .utf8)!

        let response = try JSONDecoder().decode(STKPushResponse.self, from: json)
        XCTAssertTrue(response.isSuccessful)
    }

    func testResponseFailure() throws {
        let json = """
        {
            "MerchantRequestID": "fail-id",
            "CheckoutRequestID": "ws_CO_fail",
            "ResponseCode": "1",
            "ResponseDescription": "Rejected",
            "CustomerMessage": "Rejected"
        }
        """.data(using: .utf8)!

        let response = try JSONDecoder().decode(STKPushResponse.self, from: json)
        XCTAssertFalse(response.isSuccessful)
    }

    // MARK: - STKPushCallback Tests

    func testSuccessCallbackDecoding() throws {
        let json = """
        {
            "Body": {
                "stkCallback": {
                    "MerchantRequestID": "29115-34620561-1",
                    "CheckoutRequestID": "ws_CO_191220191020363925",
                    "ResultCode": 0,
                    "ResultDesc": "The service request is processed successfully.",
                    "CallbackMetadata": {
                        "Item": [
                            { "Name": "Amount", "Value": 1.00 },
                            { "Name": "MpesaReceiptNumber", "Value": "NLJ7RT61SV" },
                            { "Name": "TransactionDate", "Value": 20191219102115 },
                            { "Name": "PhoneNumber", "Value": 254708374149 }
                        ]
                    }
                }
            }
        }
        """.data(using: .utf8)!

        let callback = try JSONDecoder().decode(STKPushCallback.self, from: json)

        XCTAssertEqual(callback.merchantRequestID, "29115-34620561-1")
        XCTAssertEqual(callback.checkoutRequestID, "ws_CO_191220191020363925")
        XCTAssertEqual(callback.resultCode, 0)
        XCTAssertTrue(callback.isSuccessful)
        XCTAssertEqual(callback.resultCodeEnum, .success)
        XCTAssertEqual(callback.amount, 1.00)
        XCTAssertEqual(callback.mpesaReceiptNumber, "NLJ7RT61SV")
        XCTAssertEqual(callback.transactionDate, 20191219102115)
        XCTAssertEqual(callback.phoneNumber, 254708374149)
    }

    func testFailureCallbackDecoding() throws {
        let json = """
        {
            "Body": {
                "stkCallback": {
                    "MerchantRequestID": "f1e2-4b95-a71d-b30d3cdbb7a7942864",
                    "CheckoutRequestID": "ws_CO_21072024125243250722943992",
                    "ResultCode": 1032,
                    "ResultDesc": "Request cancelled by user"
                }
            }
        }
        """.data(using: .utf8)!

        let callback = try JSONDecoder().decode(STKPushCallback.self, from: json)

        XCTAssertEqual(callback.resultCode, 1032)
        XCTAssertFalse(callback.isSuccessful)
        XCTAssertEqual(callback.resultCodeEnum, .cancelledByUser)
        XCTAssertNil(callback.callbackMetadata)
        XCTAssertNil(callback.amount)
        XCTAssertNil(callback.mpesaReceiptNumber)
    }

    func testCallbackWithIntAmount() throws {
        let json = """
        {
            "Body": {
                "stkCallback": {
                    "MerchantRequestID": "int-amount-test",
                    "CheckoutRequestID": "ws_CO_int",
                    "ResultCode": 0,
                    "ResultDesc": "Success",
                    "CallbackMetadata": {
                        "Item": [
                            { "Name": "Amount", "Value": 100 },
                            { "Name": "MpesaReceiptNumber", "Value": "ABC123" },
                            { "Name": "TransactionDate", "Value": 20240710091526 },
                            { "Name": "PhoneNumber", "Value": 254722000000 }
                        ]
                    }
                }
            }
        }
        """.data(using: .utf8)!

        let callback = try JSONDecoder().decode(STKPushCallback.self, from: json)

        // Int values should be convertible to Double via the doubleValue helper
        XCTAssertEqual(callback.amount, 100.0)
    }

    // MARK: - Result Code Tests

    func testResultCodeEnum() {
        XCTAssertEqual(STKPushResultCode.success.rawValue, 0)
        XCTAssertEqual(STKPushResultCode.cancelledByUser.rawValue, 1032)
        XCTAssertEqual(STKPushResultCode.transactionExpired.rawValue, 1019)
        XCTAssertEqual(STKPushResultCode.wrongPin.rawValue, 2001)
        XCTAssertEqual(STKPushResultCode.insufficientBalance.rawValue, 1)
    }

    // MARK: - Callback Parse via Service

    func testParseCallbackViaService() throws {
        let json = """
        {
            "Body": {
                "stkCallback": {
                    "MerchantRequestID": "parse-test",
                    "CheckoutRequestID": "ws_CO_parse",
                    "ResultCode": 0,
                    "ResultDesc": "Success",
                    "CallbackMetadata": {
                        "Item": [
                            { "Name": "Amount", "Value": 500.00 },
                            { "Name": "MpesaReceiptNumber", "Value": "XYZ789" },
                            { "Name": "TransactionDate", "Value": 20240101120000 },
                            { "Name": "PhoneNumber", "Value": 254711000000 }
                        ]
                    }
                }
            }
        }
        """.data(using: .utf8)!

        let callback = try STKPushService.parseCallback(from: json)
        XCTAssertTrue(callback.isSuccessful)
        XCTAssertEqual(callback.mpesaReceiptNumber, "XYZ789")
    }

    func testParseCallbackInvalidJSON() {
        let invalidData = "not json".data(using: .utf8)!

        XCTAssertThrowsError(try STKPushService.parseCallback(from: invalidData)) { error in
            XCTAssertTrue(error is MpesaError)
        }
    }
}
