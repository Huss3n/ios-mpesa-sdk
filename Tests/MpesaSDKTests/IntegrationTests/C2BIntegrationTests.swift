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
///
/// Run with: swift test
/// Requires MPESA_CONSUMER_KEY and MPESA_CONSUMER_SECRET in .env
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

        XCTAssertNotNil(response.originatorConversationID)
        XCTAssertTrue(response.isSuccessful)
    }

    func testRegisterURLsWithCancelledResponseType() async throws {
        try skipIfNoCredentials()

        try await Task.sleep(nanoseconds: 2_000_000_000)

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
        try await Task.sleep(nanoseconds: 2_000_000_000)

        do {
            _ = try await mpesa.c2b.registerURLs(
                shortCode: TestConfiguration.shortCode,
                responseType: .completed,
                confirmationURL: URL(string: "https://example.com/c2b/confirm")!,
                validationURL: URL(string: "https://example.com/c2b/validate")!
            )

            try await Task.sleep(nanoseconds: 1_000_000_000)

            let response = try await mpesa.c2b.simulate(
                shortCode: TestConfiguration.shortCode,
                commandID: .customerPayBillOnline,
                amount: 100,
                msisdn: TestConfiguration.testMSISDN,
                billRefNumber: "TestAccount123"
            )

            XCTAssertTrue(response.isSuccessful)
            XCTAssertNotNil(response.originatorConversationID)
        } catch let error as MpesaError {
            try skipIfWAFBlocked(error)
            throw error
        }
    }

    func testSimulateBuyGoodsTransaction() async throws {
        try skipIfNoCredentials()
        try await Task.sleep(nanoseconds: 3_000_000_000)

        do {
            _ = try await mpesa.c2b.registerURLs(
                shortCode: TestConfiguration.shortCode,
                responseType: .completed,
                confirmationURL: URL(string: "https://example.com/c2b/confirm")!,
                validationURL: URL(string: "https://example.com/c2b/validate")!
            )

            try await Task.sleep(nanoseconds: 1_000_000_000)

            let response = try await mpesa.c2b.simulate(
                shortCode: TestConfiguration.shortCode,
                commandID: .customerBuyGoodsOnline,
                amount: 50,
                msisdn: TestConfiguration.testMSISDN,
                billRefNumber: nil
            )

            XCTAssertTrue(response.isSuccessful)
        } catch let error as MpesaError {
            try skipIfWAFBlocked(error)
            throw error
        }
    }

    func testSimulateWithRequestObject() async throws {
        try skipIfNoCredentials()
        try await Task.sleep(nanoseconds: 4_000_000_000)

        do {
            _ = try await mpesa.c2b.registerURLs(
                shortCode: TestConfiguration.shortCode,
                responseType: .completed,
                confirmationURL: URL(string: "https://example.com/c2b/confirm")!,
                validationURL: URL(string: "https://example.com/c2b/validate")!
            )

            try await Task.sleep(nanoseconds: 1_000_000_000)

            let request = C2BSimulateRequest(
                shortCode: TestConfiguration.shortCode,
                commandID: .customerPayBillOnline,
                amount: 200,
                msisdn: TestConfiguration.testMSISDN,
                billRefNumber: "Invoice001"
            )

            let response = try await mpesa.c2b.simulate(request)
            XCTAssertTrue(response.isSuccessful)
        } catch let error as MpesaError {
            try skipIfWAFBlocked(error)
            throw error
        }
    }

    // MARK: - Helpers

    private func skipIfNoCredentials() throws {
        try XCTSkipUnless(
            TestConfiguration.hasCredentials,
            "Skipping integration test: MPESA_CONSUMER_KEY and MPESA_CONSUMER_SECRET not set"
        )
    }

    private func skipIfWAFBlocked(_ error: MpesaError) throws {
        if case .serverError(let statusCode, _) = error, statusCode == 403 {
            throw XCTSkip("Sandbox WAF blocked request (403). Test via Daraja web simulator instead.")
        }
    }
}
