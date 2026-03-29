//
//  B2CServiceTests.swift
//  MpesaSDK
//
//  Created by Muktar Aisak on 29/3/2026.
//

import XCTest
@testable import MpesaSDK

final class B2CServiceTests: XCTestCase {

    var mockClient: MockAPIClient!
    var tokenManager: TokenManager!
    var b2cService: B2CService!

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
        b2cService = B2CService(
            apiClient: mockClient,
            tokenManager: tokenManager
        )
    }

    override func tearDown() {
        mockClient = nil
        tokenManager = nil
        b2cService = nil
        super.tearDown()
    }

    // MARK: - Payment

    func testPaymentSuccess() async throws {
        mockClient.responses["mpesa/b2c/v3/paymentrequest"] = B2CResponse(
            originatorConversationID: "600997_Test_32et3241ed8yu",
            conversationID: "AG_20240706_20106e9209f64bebd05b",
            responseCode: "0",
            responseDescription: "Accept the service request successfully."
        )

        let response = try await b2cService.payment(
            originatorConversationID: "600997_Test_32et3241ed8yu",
            initiatorName: "testapi",
            securityCredential: "encryptedCred",
            amount: 10,
            partyA: "600992",
            partyB: "254705912645",
            resultURL: URL(string: "https://example.com/result")!,
            queueTimeOutURL: URL(string: "https://example.com/timeout")!
        )

        XCTAssertTrue(response.isSuccessful)
        XCTAssertEqual(
            response.originatorConversationID,
            "600997_Test_32et3241ed8yu"
        )
        XCTAssertEqual(
            response.conversationID,
            "AG_20240706_20106e9209f64bebd05b"
        )
        XCTAssertEqual(
            mockClient.lastEndpoint?.path,
            "mpesa/b2c/v3/paymentrequest"
        )
    }

    func testPaymentWithRequestObject() async throws {
        mockClient.responses["mpesa/b2c/v3/paymentrequest"] = B2CResponse(
            originatorConversationID: "req-obj-id",
            conversationID: "AG_req",
            responseCode: "0",
            responseDescription: "Success"
        )

        let request = B2CRequest(
            originatorConversationID: "req-obj-id",
            initiatorName: "testapi",
            securityCredential: "encryptedCred",
            commandID: .salaryPayment,
            amount: 50000,
            partyA: "600992",
            partyB: "254705912645",
            remarks: "Salary payment",
            resultURL: URL(string: "https://example.com/result")!,
            queueTimeOutURL: URL(string: "https://example.com/timeout")!,
            occasion: "MonthlySalary"
        )

        let response = try await b2cService.payment(request)

        XCTAssertTrue(response.isSuccessful)
        XCTAssertEqual(response.conversationID, "AG_req")
    }

    // MARK: - Token Handling

    func testServiceSendsBearerToken() async throws {
        mockClient.responses["mpesa/b2c/v3/paymentrequest"] = B2CResponse(
            originatorConversationID: "token-test",
            conversationID: "AG_token",
            responseCode: "0",
            responseDescription: "Success"
        )

        _ = try await b2cService.payment(
            originatorConversationID: "token-test",
            initiatorName: "testapi",
            securityCredential: "encryptedCred",
            amount: 10,
            partyA: "600992",
            partyB: "254705912645",
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
        mockClient.responses["mpesa/b2c/v3/paymentrequest"] = B2CResponse(
            originatorConversationID: "endpoint-test",
            conversationID: "AG_endpoint",
            responseCode: "0",
            responseDescription: "Success"
        )

        _ = try await b2cService.payment(
            originatorConversationID: "endpoint-test",
            initiatorName: "testapi",
            securityCredential: "encryptedCred",
            amount: 10,
            partyA: "600992",
            partyB: "254705912645",
            resultURL: URL(string: "https://example.com/result")!,
            queueTimeOutURL: URL(string: "https://example.com/timeout")!
        )

        XCTAssertEqual(
            mockClient.lastEndpoint?.path,
            "mpesa/b2c/v3/paymentrequest"
        )
    }

    // MARK: - Error Handling

    func testServicePropagatesError() async {
        // No mock response set — should throw
        do {
            _ = try await b2cService.payment(
                originatorConversationID: "error-test",
                initiatorName: "testapi",
                securityCredential: "encryptedCred",
                amount: 10,
                partyA: "600992",
                partyB: "254705912645",
                resultURL: URL(string: "https://example.com/result")!,
                queueTimeOutURL: URL(string: "https://example.com/timeout")!
            )
            XCTFail("Expected error to be thrown")
        } catch {
            XCTAssertTrue(error is MpesaError)
        }
    }
}
