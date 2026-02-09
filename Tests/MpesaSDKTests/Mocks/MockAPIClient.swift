//
//  MockAPIClient.swift
//  MpesaSDK
//
//  Created by Muktar Aisak on 10/2/2026.
//

import Foundation
@testable import MpesaSDK

final class MockAPIClient: APIClientProtocol, @unchecked Sendable {
    var responses: [String: Any] = [:]
    var lastEndpoint: Endpoint?
    var lastHeaders: [String: String]?

    func send<T: Decodable>(
        endpoint: Endpoint,
        body: Encodable?,
        headers: [String: String]
    ) async throws -> T {
        lastEndpoint = endpoint
        lastHeaders = headers

        guard let response = responses[endpoint.path] as? T else {
            throw MpesaError.unknown("No mock response for \(endpoint.path)")
        }

        return response
    }
}
