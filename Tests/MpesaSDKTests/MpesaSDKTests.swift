//
//  MpesaSDKTests.swift
//  MpesaSDK
//
//  Created by Muktar Aisak on 9/2/2026.
//

import XCTest
@testable import MpesaSDK

final class MpesaSDKTests: XCTestCase {

    func testConfigurationInitialization() {
        let config = MpesaConfiguration(
            consumerKey: "testKey",
            consumerSecret: "testSecret",
            environment: .sandbox
        )

        XCTAssertEqual(config.consumerKey, "testKey")
        XCTAssertEqual(config.consumerSecret, "testSecret")
    }

    func testBasicAuthCredentials() {
        let config = MpesaConfiguration(
            consumerKey: "key",
            consumerSecret: "secret",
            environment: .sandbox
        )

        let expected = Data("key:secret".utf8).base64EncodedString()
        XCTAssertEqual(config.basicAuthCredentials, expected)
    }

    func testEnvironmentBaseURLs() {
        XCTAssertEqual(
            MpesaEnvironment.sandbox.baseURL.absoluteString,
            "https://sandbox.safaricom.co.ke"
        )
        XCTAssertEqual(
            MpesaEnvironment.production.baseURL.absoluteString,
            "https://api.safaricom.co.ke"
        )
    }

    func testMpesaInitialization() {
        let mpesa = Mpesa(
            consumerKey: "testKey",
            consumerSecret: "testSecret",
            environment: .sandbox
        )

        XCTAssertNotNil(mpesa.c2b)
    }
}
