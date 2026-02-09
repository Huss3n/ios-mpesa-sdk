# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added
- Initial SDK setup with Swift Package Manager
- OAuth 2.0 authentication with automatic token management
- C2B (Customer to Business) API support
  - Register validation and confirmation URLs
  - Simulate transactions (sandbox only)
  - Callback parsing utilities
  - Validation response helpers
- Comprehensive error handling with `MpesaError`
- Unit tests for models and encoding/decoding
- Integration tests for sandbox API

### Security
- Credentials stored in environment variables
- Token caching with actor-based thread safety

## [1.0.0] - Unreleased

### Added
- Initial public release
