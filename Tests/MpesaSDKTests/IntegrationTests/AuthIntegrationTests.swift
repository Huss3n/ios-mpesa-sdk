//
//  AuthIntegrationTests.swift
//  MpesaSDK
//
//  Created by Muktar Aisak on 10/2/2026.
//

import XCTest
@testable import MpesaSDK

/// Integration tests for OAuth authentication.
/// These tests hit the actual M-Pesa sandbox API.
final class AuthIntegrationTests: XCTestCase {

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

    func testAuthenticationSuccess() async throws {
        try skipIfNoCredentials()

        // The C2B service will internally authenticate
        // If this doesn't throw, auth worked
        let response = try await mpesa.c2b.registerURLs(
            shortCode: TestConfiguration.shortCode,
            responseType: .completed,
            confirmationURL: URL(string: "https://example.com/confirm")!,
            validationURL: URL(string: "https://example.com/validate")!
        )

        // If we got here, authentication succeeded
        XCTAssertNotNil(response.originatorConversationID)
    }

    func testInvalidCredentialsFails() async {
        let invalidMpesa = Mpesa(
            consumerKey: "invalid_key",
            consumerSecret: "invalid_secret",
            environment: .sandbox
        )

        do {
            _ = try await invalidMpesa.c2b.registerURLs(
                shortCode: TestConfiguration.shortCode,
                responseType: .completed,
                confirmationURL: URL(string: "https://example.com/confirm")!,
                validationURL: URL(string: "https://example.com/validate")!
            )
            XCTFail("Expected authentication to fail")
        } catch {
            // Expected - invalid credentials should fail
            XCTAssertTrue(true)
        }
    }

    // MARK: - Helpers

    private func skipIfNoCredentials() throws {
        try XCTSkipUnless(
            TestConfiguration.hasCredentials,
            "Skipping integration test: MPESA_CONSUMER_KEY and MPESA_CONSUMER_SECRET not set"
        )
    }
}
