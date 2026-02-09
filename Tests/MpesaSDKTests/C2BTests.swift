//
//  C2BTests.swift
//  MpesaSDK
//
//  Created by Muktar Aisak on 9/2/2026.
//

import XCTest
@testable import MpesaSDK

final class C2BTests: XCTestCase {

    // MARK: - C2BRegisterURLRequest Tests

    func testRegisterURLRequestEncoding() throws {
        let request = C2BRegisterURLRequest(
            shortCode: "600984",
            responseType: .completed,
            confirmationURL: URL(string: "https://example.com/confirm")!,
            validationURL: URL(string: "https://example.com/validate")!
        )

        let data = try JSONEncoder().encode(request)
        let json = try JSONSerialization.jsonObject(with: data) as! [String: Any]

        XCTAssertEqual(json["ShortCode"] as? String, "600984")
        XCTAssertEqual(json["ResponseType"] as? String, "Completed")
        XCTAssertEqual(json["ConfirmationURL"] as? String, "https://example.com/confirm")
        XCTAssertEqual(json["ValidationURL"] as? String, "https://example.com/validate")
    }

    func testResponseTypeCasing() {
        XCTAssertEqual(C2BResponseType.completed.rawValue, "Completed")
        XCTAssertEqual(C2BResponseType.cancelled.rawValue, "Cancelled")
    }

    // MARK: - C2BSimulateRequest Tests

    func testSimulateRequestEncoding() throws {
        let request = C2BSimulateRequest(
            shortCode: "600984",
            commandID: .customerPayBillOnline,
            amount: 100,
            msisdn: "254708374149",
            billRefNumber: "TestRef"
        )

        let data = try JSONEncoder().encode(request)
        let json = try JSONSerialization.jsonObject(with: data) as! [String: Any]

        XCTAssertEqual(json["ShortCode"] as? Int, 600984)
        XCTAssertEqual(json["CommandID"] as? String, "CustomerPayBillOnline")
        XCTAssertEqual(json["Amount"] as? Int, 100)
        XCTAssertEqual(json["Msisdn"] as? Int, 254708374149)
        XCTAssertEqual(json["BillRefNumber"] as? String, "TestRef")
    }

    func testCommandIDValues() {
        XCTAssertEqual(C2BCommandID.customerBuyGoodsOnline.rawValue, "CustomerBuyGoodsOnline")
        XCTAssertEqual(C2BCommandID.customerPayBillOnline.rawValue, "CustomerPayBillOnline")
    }

    // MARK: - C2BCallback Tests

    func testCallbackDecoding() throws {
        let json = """
        {
            "TransactionType": "Pay Bill",
            "TransID": "RKL51ZDR4F",
            "TransTime": "20231121121325",
            "TransAmount": "500.00",
            "BusinessShortCode": "600966",
            "BillRefNumber": "Test Account",
            "InvoiceNumber": "",
            "OrgAccountBalance": "25000.00",
            "ThirdPartyTransID": "",
            "MSISDN": "2547 ***** 126",
            "FirstName": "JOHN",
            "MiddleName": "DOE",
            "LastName": "SMITH"
        }
        """.data(using: .utf8)!

        let callback = try JSONDecoder().decode(C2BCallback.self, from: json)

        XCTAssertEqual(callback.transactionType, "Pay Bill")
        XCTAssertEqual(callback.transID, "RKL51ZDR4F")
        XCTAssertEqual(callback.transAmount, "500.00")
        XCTAssertEqual(callback.businessShortCode, "600966")
        XCTAssertEqual(callback.billRefNumber, "Test Account")
        XCTAssertEqual(callback.firstName, "JOHN")
        XCTAssertEqual(callback.customerName, "JOHN DOE SMITH")
    }

    func testCallbackAmountParsing() throws {
        let json = """
        {
            "TransactionType": "Pay Bill",
            "TransID": "ABC123",
            "TransTime": "20231121121325",
            "TransAmount": "1500.50",
            "BusinessShortCode": "600966",
            "BillRefNumber": "",
            "InvoiceNumber": "",
            "OrgAccountBalance": "",
            "ThirdPartyTransID": "",
            "MSISDN": "254700000000",
            "FirstName": "",
            "MiddleName": "",
            "LastName": ""
        }
        """.data(using: .utf8)!

        let callback = try JSONDecoder().decode(C2BCallback.self, from: json)

        XCTAssertEqual(callback.amount, Decimal(string: "1500.50"))
    }

    // MARK: - C2BValidationResponse Tests

    func testValidationAcceptResponse() throws {
        let response = C2BValidationResponse.accept()

        let data = try JSONEncoder().encode(response)
        let json = try JSONSerialization.jsonObject(with: data) as! [String: Any]

        XCTAssertEqual(json["ResultCode"] as? String, "0")
        XCTAssertEqual(json["ResultDesc"] as? String, "Accepted")
    }

    func testValidationRejectResponse() throws {
        let response = C2BValidationResponse.rejectInvalidAccountNumber()

        let data = try JSONEncoder().encode(response)
        let json = try JSONSerialization.jsonObject(with: data) as! [String: Any]

        XCTAssertEqual(json["ResultCode"] as? String, "C2B00012")
        XCTAssertEqual(json["ResultDesc"] as? String, "Invalid account number")
    }

    // MARK: - Response Decoding Tests

    func testRegisterURLResponseDecoding() throws {
        let json = """
        {
            "OriginatorCoversationID": "6e86-45dd-91ac-fd5d4178ab523408729",
            "ResponseCode": "0",
            "ResponseDescription": "Success"
        }
        """.data(using: .utf8)!

        let response = try JSONDecoder().decode(C2BRegisterURLResponse.self, from: json)

        XCTAssertEqual(response.originatorConversationID, "6e86-45dd-91ac-fd5d4178ab523408729")
        XCTAssertEqual(response.responseCode, "0")
        XCTAssertTrue(response.isSuccessful)
    }

    func testSimulateResponseDecoding() throws {
        let json = """
        {
            "OriginatorCoversationID": "53e3-4aa8-9fe0-8fb5e4092cdd3405976",
            "ResponseCode": "0",
            "ResponseDescription": "Accept the service request successfully."
        }
        """.data(using: .utf8)!

        let response = try JSONDecoder().decode(C2BSimulateResponse.self, from: json)

        XCTAssertEqual(response.originatorConversationID, "53e3-4aa8-9fe0-8fb5e4092cdd3405976")
        XCTAssertTrue(response.isSuccessful)
    }
}
