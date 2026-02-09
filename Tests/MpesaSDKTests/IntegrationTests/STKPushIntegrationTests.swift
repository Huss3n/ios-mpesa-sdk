//
//  STKPushIntegrationTests.swift
//  MpesaSDK
//
//  Created by Muktar Aisak on 10/2/2026.
//

import XCTest
@testable import MpesaSDK

/// Integration tests for STK Push API.
/// These tests hit the actual M-Pesa sandbox API.
///
/// Run with: swift test
/// Requires MPESA_CONSUMER_KEY and MPESA_CONSUMER_SECRET in .env
final class STKPushIntegrationTests: XCTestCase {

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

    // MARK: - STK Push Tests

    func testInitiatePaymentSuccess() async throws {
        try skipIfNoCredentials()

        do {
            let response = try await mpesa.stkPush.initiatePayment(
                businessShortCode: TestConfiguration.stkPushShortCode,
                passKey: TestConfiguration.stkPushPassKey,
                amount: 1,
                phoneNumber: TestConfiguration.testMSISDN,
                callbackURL: URL(string: "https://example.com/stk/callback")!,
                accountReference: "TestSDK"
            )

            XCTAssertTrue(response.isSuccessful)
            XCTAssertFalse(response.merchantRequestID.isEmpty)
            XCTAssertFalse(response.checkoutRequestID.isEmpty)
        } catch let error as MpesaError {
            try skipIfWAFBlocked(error)
            throw error
        }
    }

    func testInitiatePaymentWithRequestObject() async throws {
        try skipIfNoCredentials()
        try await Task.sleep(nanoseconds: 5_000_000_000)

        do {
            let request = STKPushRequest(
                businessShortCode: TestConfiguration.stkPushShortCode,
                passKey: TestConfiguration.stkPushPassKey,
                amount: 10,
                phoneNumber: TestConfiguration.testMSISDN,
                callbackURL: URL(string: "https://example.com/stk/callback")!,
                accountReference: "Inv001",
                transactionDesc: "Invoice Pay"
            )

            let response = try await mpesa.stkPush.initiatePayment(request)
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
            throw XCTSkip(
                "Sandbox WAF blocked request (403). Test via Daraja web simulator instead."
            )
        }
        if case .apiError(let code, _) = error, code == "500.003.02" {
            throw XCTSkip("Sandbox rate limited (System is busy). Try again later.")
        }
    }
}
