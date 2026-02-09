//
//  TestConfiguration.swift
//  MpesaSDK
//
//  Created by Muktar Aisak on 10/2/2026.
//

import Foundation

/// Configuration for integration tests.
/// Reads credentials from environment variables or .env file.
enum TestConfiguration {

    private static var envVars: [String: String] = {
        var vars = ProcessInfo.processInfo.environment

        // Try to load from .env file if env vars not set
        if vars["MPESA_CONSUMER_KEY"] == nil {
            loadEnvFile(into: &vars)
        }

        return vars
    }()

    static var consumerKey: String? {
        envVars["MPESA_CONSUMER_KEY"]
    }

    static var consumerSecret: String? {
        envVars["MPESA_CONSUMER_SECRET"]
    }

    static var shortCode: String {
        envVars["MPESA_SHORTCODE"] ?? "600984"
    }

    static var testMSISDN: String {
        envVars["MPESA_TEST_MSISDN"] ?? "254708374149"
    }

    static var hasCredentials: Bool {
        consumerKey != nil && consumerSecret != nil
    }

    private static func loadEnvFile(into vars: inout [String: String], filePath: String = #file) {
        let fileManager = FileManager.default

        // Walk up from the source file location to find .env at the project root
        var currentPath = (filePath as NSString).deletingLastPathComponent

        for _ in 0..<10 {
            let envPath = (currentPath as NSString).appendingPathComponent(".env")
            if fileManager.fileExists(atPath: envPath),
               let contents = try? String(contentsOfFile: envPath, encoding: .utf8) {
                parseEnvFile(contents, into: &vars)
                return
            }
            let parent = (currentPath as NSString).deletingLastPathComponent
            if parent == currentPath { break }
            currentPath = parent
        }
    }

    private static func parseEnvFile(_ contents: String, into vars: inout [String: String]) {
        let lines = contents.components(separatedBy: .newlines)

        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespaces)

            // Skip empty lines and comments
            guard !trimmed.isEmpty, !trimmed.hasPrefix("#") else { continue }

            let parts = trimmed.split(separator: "=", maxSplits: 1)
            guard parts.count == 2 else { continue }

            let key = String(parts[0]).trimmingCharacters(in: .whitespaces)
            let value = String(parts[1]).trimmingCharacters(in: .whitespaces)

            vars[key] = value
        }
    }
}
