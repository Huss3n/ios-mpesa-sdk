//
//  B2CTopUpServiceTests.swift
//  MpesaSDK
//
//  Created by Muktar Aisak on 12/2/2026.
//

import XCTest
@testable import MpesaSDK

final class B2CTopUpServiceTests: XCTestCase {

    var mockClient: MockAPIClient!
    var tokenManager: TokenManager!
    var b2cTopUpService: B2CTopUpService!

    override func setUp() {
        super.setUp()

        mockClient = MockAPIClient()

        let config = MpesaConfiguration(
            consumerKey: "testKey",
            consumerSecret: "testSecret",
            environment: .sandbox
        )

        mockClient.responses["oauth/v1/generate"] = AccessToken(
            accessToken: "mock_token_b2c",
            expiresIn: "3599"
        )

        tokenManager = TokenManager(configuration: config, apiClient: mockClient)
        b2cTopUpService = B2CTopUpService(
            apiClient: mockClient,
            tokenManager: tokenManager
        )
    }

    override func tearDown() {
        mockClient = nil
        tokenManager = nil
        b2cTopUpService = nil
        super.tearDown()
    }

    // MARK: - Top Up

    func testTopUpSuccess() async throws {
        mockClient.responses["mpesa/b2b/v1/paymentrequest"] = B2CTopUpResponse(
            originatorConversationID: "test-orig-id",
            conversationID: "AG_test",
            responseCode: "0",
            responseDescription: "Accept the service request successfully."
        )

        let response = try await b2cTopUpService.topUp(
            initiator: "testInitiator",
            securityCredential: "encryptedCred",
            partyA: "600984",
            partyB: "600000",
            amount: 239,
            accountReference: "353353",
            resultURL: URL(string: "https://example.com/result")!,
            queueTimeOutURL: URL(string: "https://example.com/timeout")!
        )

        XCTAssertTrue(response.isSuccessful)
        XCTAssertEqual(response.originatorConversationID, "test-orig-id")
        XCTAssertEqual(response.conversationID, "AG_test")
        XCTAssertEqual(
            mockClient.lastEndpoint?.path,
            "mpesa/b2b/v1/paymentrequest"
        )
    }

    func testTopUpWithRequestObject() async throws {
        mockClient.responses["mpesa/b2b/v1/paymentrequest"] = B2CTopUpResponse(
            originatorConversationID: "req-obj-id",
            conversationID: "AG_req",
            responseCode: "0",
            responseDescription: "Success"
        )

        let request = B2CTopUpRequest(
            initiator: "testInitiator",
            securityCredential: "encryptedCred",
            partyA: "600984",
            partyB: "600000",
            amount: 500,
            accountReference: "353353",
            resultURL: URL(string: "https://example.com/result")!,
            queueTimeOutURL: URL(string: "https://example.com/timeout")!,
            requester: "254722000000",
            remarks: "Top up"
        )

        let response = try await b2cTopUpService.topUp(request)

        XCTAssertTrue(response.isSuccessful)
        XCTAssertEqual(response.conversationID, "AG_req")
    }

    // MARK: - Token Handling

    func testServiceSendsBearerToken() async throws {
        mockClient.responses["mpesa/b2b/v1/paymentrequest"] = B2CTopUpResponse(
            originatorConversationID: "token-test",
            conversationID: "AG_token",
            responseCode: "0",
            responseDescription: "Success"
        )

        _ = try await b2cTopUpService.topUp(
            initiator: "testInitiator",
            securityCredential: "encryptedCred",
            partyA: "600984",
            partyB: "600000",
            amount: 1,
            accountReference: "ref",
            resultURL: URL(string: "https://example.com/result")!,
            queueTimeOutURL: URL(string: "https://example.com/timeout")!
        )

        XCTAssertEqual(
            mockClient.lastHeaders?["Authorization"],
            "Bearer mock_token_b2c"
        )
    }

    // MARK: - Endpoint Routing

    func testEndpointPath() async throws {
        mockClient.responses["mpesa/b2b/v1/paymentrequest"] = B2CTopUpResponse(
            originatorConversationID: "endpoint-test",
            conversationID: "AG_endpoint",
            responseCode: "0",
            responseDescription: "Success"
        )

        _ = try await b2cTopUpService.topUp(
            initiator: "testInitiator",
            securityCredential: "encryptedCred",
            partyA: "600984",
            partyB: "600000",
            amount: 1,
            accountReference: "ref",
            resultURL: URL(string: "https://example.com/result")!,
            queueTimeOutURL: URL(string: "https://example.com/timeout")!
        )

        XCTAssertEqual(
            mockClient.lastEndpoint?.path,
            "mpesa/b2b/v1/paymentrequest"
        )
    }

    // MARK: - Error Handling

    func testServicePropagatesError() async {
        // No mock response set — should throw
        do {
            _ = try await b2cTopUpService.topUp(
                initiator: "testInitiator",
                securityCredential: "encryptedCred",
                partyA: "600984",
                partyB: "600000",
                amount: 1,
                accountReference: "ref",
                resultURL: URL(string: "https://example.com/result")!,
                queueTimeOutURL: URL(string: "https://example.com/timeout")!
            )
            XCTFail("Expected error to be thrown")
        } catch {
            XCTAssertTrue(error is MpesaError)
        }
    }
}
