//
//  STKPushServiceTests.swift
//  MpesaSDK
//
//  Created by Muktar Aisak on 10/2/2026.
//

import XCTest
@testable import MpesaSDK

final class STKPushServiceTests: XCTestCase {

    var mockClient: MockAPIClient!
    var tokenManager: TokenManager!
    var stkPushService: STKPushService!

    override func setUp() {
        super.setUp()

        mockClient = MockAPIClient()

        let config = MpesaConfiguration(
            consumerKey: "testKey",
            consumerSecret: "testSecret",
            environment: .sandbox
        )

        // Provide a mock token response so TokenManager works
        mockClient.responses["oauth/v1/generate"] = AccessToken(
            accessToken: "mock_token_456",
            expiresIn: "3599"
        )

        tokenManager = TokenManager(configuration: config, apiClient: mockClient)
        stkPushService = STKPushService(apiClient: mockClient, tokenManager: tokenManager)
    }

    override func tearDown() {
        mockClient = nil
        tokenManager = nil
        stkPushService = nil
        super.tearDown()
    }

    // MARK: - Initiate Payment

    func testInitiatePaymentSuccess() async throws {
        mockClient.responses["mpesa/stkpush/v1/processrequest"] = STKPushResponse(
            merchantRequestID: "test-merchant-id",
            checkoutRequestID: "ws_CO_test",
            responseCode: "0",
            responseDescription: "Success. Request accepted for processing",
            customerMessage: "Success. Request accepted for processing"
        )

        let response = try await stkPushService.initiatePayment(
            businessShortCode: "174379",
            passKey: "testPassKey",
            amount: 1,
            phoneNumber: "254722000000",
            callbackURL: URL(string: "https://example.com/callback")!,
            accountReference: "TestRef"
        )

        XCTAssertTrue(response.isSuccessful)
        XCTAssertEqual(response.merchantRequestID, "test-merchant-id")
        XCTAssertEqual(response.checkoutRequestID, "ws_CO_test")
        XCTAssertEqual(mockClient.lastEndpoint?.path, "mpesa/stkpush/v1/processrequest")
    }

    func testInitiatePaymentWithRequestObject() async throws {
        mockClient.responses["mpesa/stkpush/v1/processrequest"] = STKPushResponse(
            merchantRequestID: "req-obj-id",
            checkoutRequestID: "ws_CO_req",
            responseCode: "0",
            responseDescription: "Success",
            customerMessage: "Success"
        )

        let request = STKPushRequest(
            businessShortCode: "174379",
            passKey: "testPassKey",
            amount: 100,
            phoneNumber: "254722000000",
            callbackURL: URL(string: "https://example.com/callback")!,
            accountReference: "Invoice001",
            transactionDesc: "Payment"
        )

        let response = try await stkPushService.initiatePayment(request)

        XCTAssertTrue(response.isSuccessful)
        XCTAssertEqual(response.checkoutRequestID, "ws_CO_req")
    }

    func testInitiatePaymentBuyGoods() async throws {
        mockClient.responses["mpesa/stkpush/v1/processrequest"] = STKPushResponse(
            merchantRequestID: "buy-goods-id",
            checkoutRequestID: "ws_CO_buy",
            responseCode: "0",
            responseDescription: "Success",
            customerMessage: "Success"
        )

        let request = STKPushRequest(
            businessShortCode: "174379",
            passKey: "testPassKey",
            amount: 50,
            phoneNumber: "254722000000",
            callbackURL: URL(string: "https://example.com/callback")!,
            accountReference: "TestRef",
            transactionDesc: "Buy Goods",
            transactionType: .customerBuyGoodsOnline
        )

        let response = try await stkPushService.initiatePayment(request)

        XCTAssertTrue(response.isSuccessful)
    }

    // MARK: - Token Handling

    func testServiceSendsBearerToken() async throws {
        mockClient.responses["mpesa/stkpush/v1/processrequest"] = STKPushResponse(
            merchantRequestID: "token-test",
            checkoutRequestID: "ws_CO_token",
            responseCode: "0",
            responseDescription: "Success",
            customerMessage: "Success"
        )

        _ = try await stkPushService.initiatePayment(
            businessShortCode: "174379",
            passKey: "testPassKey",
            amount: 1,
            phoneNumber: "254722000000",
            callbackURL: URL(string: "https://example.com/callback")!,
            accountReference: "TestRef"
        )

        XCTAssertEqual(
            mockClient.lastHeaders?["Authorization"],
            "Bearer mock_token_456"
        )
    }

    // MARK: - Endpoint Routing

    func testEndpointPath() async throws {
        mockClient.responses["mpesa/stkpush/v1/processrequest"] = STKPushResponse(
            merchantRequestID: "endpoint-test",
            checkoutRequestID: "ws_CO_endpoint",
            responseCode: "0",
            responseDescription: "Success",
            customerMessage: "Success"
        )

        _ = try await stkPushService.initiatePayment(
            businessShortCode: "174379",
            passKey: "testPassKey",
            amount: 1,
            phoneNumber: "254722000000",
            callbackURL: URL(string: "https://example.com/callback")!,
            accountReference: "TestRef"
        )

        XCTAssertEqual(
            mockClient.lastEndpoint?.path,
            "mpesa/stkpush/v1/processrequest"
        )
    }

    // MARK: - Error Handling

    func testServicePropagatesError() async {
        // No mock response set — should throw
        do {
            _ = try await stkPushService.initiatePayment(
                businessShortCode: "174379",
                passKey: "testPassKey",
                amount: 1,
                phoneNumber: "254722000000",
                callbackURL: URL(string: "https://example.com/callback")!,
                accountReference: "TestRef"
            )
            XCTFail("Expected error to be thrown")
        } catch {
            XCTAssertTrue(error is MpesaError)
        }
    }
}
