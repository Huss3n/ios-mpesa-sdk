# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [1.1.0] - 2026-02-10

### Added
- STK Push (Lipa Na M-Pesa) API support
  - Initiate merchant-initiated payment prompts
  - Auto-generated password and timestamp
  - Callback parsing with type-safe metadata
  - Support for PayBill and BuyGoods transaction types
  - `STKPushResultCode` enum for all 12 known result codes
- STK Push documentation (`Documentation/STKPush.md`)
- Unit tests, mock-based service tests, and sandbox integration tests for STK Push
- STK Push shortcode and passkey to test configuration

## [1.0.0] - 2026-02-09

### Added
- Initial SDK setup with Swift Package Manager
- OAuth 2.0 authentication with automatic token management
- C2B (Customer to Business) API support
  - Register validation and confirmation URLs
  - Simulate transactions (sandbox only)
  - Callback parsing utilities
  - Validation response helpers
- C2B documentation (`Documentation/C2B.md`)
- Comprehensive error handling with `MpesaError`
- Unit tests for models and encoding/decoding
- Integration tests for sandbox API
- CI workflow with build, test, and SwiftLint checks

### Security
- Credentials stored in environment variables
- Token caching with actor-based thread safety
