//
//  C2BIntegrationTests.swift
//  MpesaSDK
//
//  Created by Muktar Aisak on 10/2/2026.
//

import XCTest
@testable import MpesaSDK

/// Integration tests for C2B API.
/// These tests hit the actual M-Pesa sandbox API.
final class C2BIntegrationTests: XCTestCase {

    var mpesa: Mpesa!

    override func setUp() {
        super.setUp()

        guard TestConfiguration.hasCredentials,
              let key = TestConfiguration.consumerKey,
              let secret = TestConfiguration.consumerSecret else {
            return
        }

        mpesa = Mpesa(
            consumerKey: key,
            consumerSecret: secret,
            environment: .sandbox
        )
    }

    override func tearDown() {
        mpesa = nil
        super.tearDown()
    }

    // MARK: - Register URL Tests

    func testRegisterURLsSuccess() async throws {
        try skipIfNoCredentials()

        let response = try await mpesa.c2b.registerURLs(
            shortCode: TestConfiguration.shortCode,
            responseType: .completed,
            confirmationURL: URL(string: "https://example.com/c2b/confirm")!,
            validationURL: URL(string: "https://example.com/c2b/validate")!
        )

        XCTAssertEqual(response.responseCode, "0")
        XCTAssertNotNil(response.originatorConversationID)
        XCTAssertTrue(response.isSuccessful)
    }

    func testRegisterURLsWithCancelledResponseType() async throws {
        try skipIfNoCredentials()

        let response = try await mpesa.c2b.registerURLs(
            shortCode: TestConfiguration.shortCode,
            responseType: .cancelled,
            confirmationURL: URL(string: "https://example.com/c2b/confirm")!,
            validationURL: URL(string: "https://example.com/c2b/validate")!
        )

        XCTAssertTrue(response.isSuccessful)
    }

    // MARK: - Simulate Tests

    func testSimulatePayBillTransaction() async throws {
        try skipIfNoCredentials()

        // First register URLs
        _ = try await mpesa.c2b.registerURLs(
            shortCode: TestConfiguration.shortCode,
            responseType: .completed,
            confirmationURL: URL(string: "https://example.com/c2b/confirm")!,
            validationURL: URL(string: "https://example.com/c2b/validate")!
        )

        // Then simulate
        let response = try await mpesa.c2b.simulate(
            shortCode: TestConfiguration.shortCode,
            commandID: .customerPayBillOnline,
            amount: 100,
            msisdn: TestConfiguration.testMSISDN,
            billRefNumber: "TestAccount123"
        )

        XCTAssertEqual(response.responseCode, "0")
        XCTAssertTrue(response.isSuccessful)
        XCTAssertNotNil(response.originatorConversationID)
    }

    func testSimulateBuyGoodsTransaction() async throws {
        try skipIfNoCredentials()

        // First register URLs
        _ = try await mpesa.c2b.registerURLs(
            shortCode: TestConfiguration.shortCode,
            responseType: .completed,
            confirmationURL: URL(string: "https://example.com/c2b/confirm")!,
            validationURL: URL(string: "https://example.com/c2b/validate")!
        )

        // Simulate Buy Goods (no bill ref number)
        let response = try await mpesa.c2b.simulate(
            shortCode: TestConfiguration.shortCode,
            commandID: .customerBuyGoodsOnline,
            amount: 50,
            msisdn: TestConfiguration.testMSISDN,
            billRefNumber: nil
        )

        XCTAssertEqual(response.responseCode, "0")
        XCTAssertTrue(response.isSuccessful)
    }

    func testSimulateWithRequestObject() async throws {
        try skipIfNoCredentials()

        // Register URLs first
        _ = try await mpesa.c2b.registerURLs(
            shortCode: TestConfiguration.shortCode,
            responseType: .completed,
            confirmationURL: URL(string: "https://example.com/c2b/confirm")!,
            validationURL: URL(string: "https://example.com/c2b/validate")!
        )

        let request = C2BSimulateRequest(
            shortCode: TestConfiguration.shortCode,
            commandID: .customerPayBillOnline,
            amount: 200,
            msisdn: TestConfiguration.testMSISDN,
            billRefNumber: "Invoice001"
        )

        let response = try await mpesa.c2b.simulate(request)

        XCTAssertTrue(response.isSuccessful)
    }

    // MARK: - Helpers

    private func skipIfNoCredentials() throws {
        try XCTSkipUnless(
            TestConfiguration.hasCredentials,
            "Skipping integration test: MPESA_CONSUMER_KEY and MPESA_CONSUMER_SECRET not set"
        )
    }
}
