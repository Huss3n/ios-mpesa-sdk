//
//  APIClient.swift
//  MpesaSDK
//
//  Created by Muktar Aisak on 4/2/2026.
//

import Foundation

/// Protocol for HTTP client operations.
protocol APIClientProtocol: Sendable {
    func send<T: Decodable>(
        endpoint: Endpoint,
        body: Encodable?,
        headers: [String: String]
    ) async throws -> T
}

/// URLSession-based API client for M-Pesa requests.
final class APIClient: APIClientProtocol, Sendable {
    private let baseURL: URL
    private let session: URLSession
    private let encoder: JSONEncoder
    private let decoder: JSONDecoder

    init(baseURL: URL, session: URLSession = .shared) {
        self.baseURL = baseURL
        self.session = session
        self.encoder = JSONEncoder()
        self.decoder = JSONDecoder()
    }

    func send<T: Decodable>(
        endpoint: Endpoint,
        body: Encodable?,
        headers: [String: String]
    ) async throws -> T {
        var request = URLRequest(url: endpoint.url(baseURL: baseURL))
        request.httpMethod = endpoint.method.rawValue
        request.timeoutInterval = 30

        // Set headers
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        for (key, value) in headers {
            request.setValue(value, forHTTPHeaderField: key)
        }

        // Set body
        if let body = body {
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.httpBody = try encoder.encode(body)
        }

        let (data, response) = try await session.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw MpesaError.unknown("Invalid response type")
        }

        // Handle error responses
        guard (200...299).contains(httpResponse.statusCode) else {
            if let errorResponse = try? decoder.decode(APIErrorResponse.self, from: data) {
                throw MpesaError.apiError(
                    code: errorResponse.errorCode ?? "\(httpResponse.statusCode)",
                    message: errorResponse.errorMessage ?? "Unknown error"
                )
            }
            throw MpesaError.serverError(
                statusCode: httpResponse.statusCode,
                message: String(data: data, encoding: .utf8) ?? "Unknown error"
            )
        }

        do {
            return try decoder.decode(T.self, from: data)
        } catch {
            throw MpesaError.decodingError(error)
        }
    }
}
