//
//  Endpoint.swift
//  MpesaSDK
//
//  Created by Muktar Aisak on 4/2/2026.
//

import Foundation

/// Defines an API endpoint configuration.
struct Endpoint {
    let path: String
    let method: HTTPMethod
    let queryItems: [URLQueryItem]?

    init(path: String, method: HTTPMethod = .post, queryItems: [URLQueryItem]? = nil) {
        self.path = path
        self.method = method
        self.queryItems = queryItems
    }

    func url(baseURL: URL) -> URL {
        var components = URLComponents(url: baseURL.appendingPathComponent(path), resolvingAgainstBaseURL: true)!
        components.queryItems = queryItems
        return components.url!
    }
}

// MARK: - Endpoints

extension Endpoint {

    // MARK: Authentication

    static let oauth = Endpoint(
        path: "oauth/v1/generate",
        method: .get,
        queryItems: [URLQueryItem(name: "grant_type", value: "client_credentials")]
    )

    // MARK: C2B

    static let c2bRegisterURL = Endpoint(path: "mpesa/c2b/v2/registerurl")
    static let c2bSimulate = Endpoint(path: "mpesa/c2b/v2/simulate")
}
