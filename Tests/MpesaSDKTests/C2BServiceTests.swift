//
//  C2BServiceTests.swift
//  MpesaSDK
//
//  Created by Muktar Aisak on 10/2/2026.
//

import XCTest
@testable import MpesaSDK

final class C2BServiceTests: XCTestCase {

    var mockClient: MockAPIClient!
    var tokenManager: TokenManager!
    var c2bService: C2BService!

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
            accessToken: "mock_token_123",
            expiresIn: "3599"
        )

        tokenManager = TokenManager(configuration: config, apiClient: mockClient)
        c2bService = C2BService(apiClient: mockClient, tokenManager: tokenManager)
    }

    override func tearDown() {
        mockClient = nil
        tokenManager = nil
        c2bService = nil
        super.tearDown()
    }

    // MARK: - Register URLs

    func testRegisterURLsSuccess() async throws {
        mockClient.responses["mpesa/c2b/v2/registerurl"] = C2BRegisterURLResponse(
            originatorConversationID: "test-conv-id",
            responseCode: "0",
            responseDescription: "Success"
        )

        let response = try await c2bService.registerURLs(
            shortCode: "600984",
            responseType: .completed,
            confirmationURL: URL(string: "https://example.com/confirm")!,
            validationURL: URL(string: "https://example.com/validate")!
        )

        XCTAssertTrue(response.isSuccessful)
        XCTAssertEqual(response.originatorConversationID, "test-conv-id")
        XCTAssertEqual(mockClient.lastEndpoint?.path, "mpesa/c2b/v2/registerurl")
        XCTAssertEqual(mockClient.lastHeaders?["Authorization"], "Bearer mock_token_123")
    }

    func testRegisterURLsWithSandboxResponseCode() async throws {
        // Real sandbox returns "00000000" instead of "0"
        mockClient.responses["mpesa/c2b/v2/registerurl"] = C2BRegisterURLResponse(
            originatorConversationID: "sandbox-conv-id",
            responseCode: "00000000",
            responseDescription: "Success"
        )

        let response = try await c2bService.registerURLs(
            shortCode: "600984",
            responseType: .completed,
            confirmationURL: URL(string: "https://example.com/confirm")!,
            validationURL: URL(string: "https://example.com/validate")!
        )

        XCTAssertTrue(response.isSuccessful)
    }

    // MARK: - Simulate

    func testSimulateSuccess() async throws {
        mockClient.responses["mpesa/c2b/v2/simulate"] = C2BSimulateResponse(
            originatorConversationID: "sim-conv-id",
            responseCode: "0",
            responseDescription: "Accept the service request successfully."
        )

        let response = try await c2bService.simulate(
            shortCode: "600984",
            commandID: .customerPayBillOnline,
            amount: 100,
            msisdn: "254708374149",
            billRefNumber: "TestRef"
        )

        XCTAssertTrue(response.isSuccessful)
        XCTAssertEqual(response.originatorConversationID, "sim-conv-id")
        XCTAssertEqual(mockClient.lastEndpoint?.path, "mpesa/c2b/v2/simulate")
        XCTAssertEqual(mockClient.lastHeaders?["Authorization"], "Bearer mock_token_123")
    }

    func testSimulateBuyGoods() async throws {
        mockClient.responses["mpesa/c2b/v2/simulate"] = C2BSimulateResponse(
            originatorConversationID: "buy-goods-id",
            responseCode: "0",
            responseDescription: "Accept the service request successfully."
        )

        let response = try await c2bService.simulate(
            shortCode: "600984",
            commandID: .customerBuyGoodsOnline,
            amount: 50,
            msisdn: "254708374149",
            billRefNumber: nil
        )

        XCTAssertTrue(response.isSuccessful)
    }

    // MARK: - Token Handling

    func testServiceSendsBearerToken() async throws {
        mockClient.responses["mpesa/c2b/v2/registerurl"] = C2BRegisterURLResponse(
            originatorConversationID: "token-test",
            responseCode: "0",
            responseDescription: "Success"
        )

        _ = try await c2bService.registerURLs(
            shortCode: "600984",
            responseType: .completed,
            confirmationURL: URL(string: "https://example.com/confirm")!,
            validationURL: URL(string: "https://example.com/validate")!
        )

        XCTAssertTrue(mockClient.lastHeaders?["Authorization"]?.hasPrefix("Bearer ") == true)
    }

    // MARK: - Error Handling

    func testServicePropagatesError() async {
        // No mock response set for registerurl — should throw
        do {
            _ = try await c2bService.registerURLs(
                shortCode: "600984",
                responseType: .completed,
                confirmationURL: URL(string: "https://example.com/confirm")!,
                validationURL: URL(string: "https://example.com/validate")!
            )
            XCTFail("Expected error to be thrown")
        } catch {
            // Expected
            XCTAssertTrue(error is MpesaError)
        }
    }
}
