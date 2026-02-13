//
//  B2CTopUpIntegrationTests.swift
//  MpesaSDK
//
//  Created by Muktar Aisak on 12/2/2026.
//

import XCTest
@testable import MpesaSDK

/// Integration tests for B2C Account Top Up API.
/// These tests hit the actual M-Pesa sandbox API.
///
/// Run with: swift test
/// Requires MPESA_CONSUMER_KEY, MPESA_CONSUMER_SECRET,
/// MPESA_B2C_INITIATOR, and MPESA_B2C_SECURITY_CREDENTIAL in .env
final class B2CTopUpIntegrationTests: XCTestCase {

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

    // MARK: - B2C Top Up Tests

    func testTopUpSuccess() async throws {
        try skipIfNoCredentials()
        try skipIfNoB2CCredentials()

        do {
            let response = try await mpesa.b2cTopUp.topUp(
                initiator: TestConfiguration.b2cInitiator,
                securityCredential: TestConfiguration.b2cSecurityCredential,
                partyA: TestConfiguration.shortCode,
                partyB: "600000",
                amount: 10,
                accountReference: "353353",
                resultURL: URL(string: "https://example.com/b2c/result")!,
                queueTimeOutURL: URL(string: "https://example.com/b2c/timeout")!
            )

            XCTAssertTrue(response.isSuccessful)
            XCTAssertFalse(response.originatorConversationID.isEmpty)
            XCTAssertFalse(response.conversationID.isEmpty)
        } catch let error as MpesaError {
            try skipIfWAFBlocked(error)
            throw error
        }
    }

    func testTopUpWithRequestObject() async throws {
        try skipIfNoCredentials()
        try skipIfNoB2CCredentials()
        try await Task.sleep(nanoseconds: 5_000_000_000)

        do {
            let request = B2CTopUpRequest(
                initiator: TestConfiguration.b2cInitiator,
                securityCredential: TestConfiguration.b2cSecurityCredential,
                partyA: TestConfiguration.shortCode,
                partyB: "600000",
                amount: 50,
                accountReference: "353353",
                resultURL: URL(string: "https://example.com/b2c/result")!,
                queueTimeOutURL: URL(string: "https://example.com/b2c/timeout")!,
                remarks: "Integration test"
            )

            let response = try await mpesa.b2cTopUp.topUp(request)
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
            "Skipping: MPESA_CONSUMER_KEY and MPESA_CONSUMER_SECRET not set"
        )
    }

    private func skipIfNoB2CCredentials() throws {
        try XCTSkipUnless(
            TestConfiguration.hasB2CCredentials,
            "Skipping: MPESA_B2C_INITIATOR and MPESA_B2C_SECURITY_CREDENTIAL not set"
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
