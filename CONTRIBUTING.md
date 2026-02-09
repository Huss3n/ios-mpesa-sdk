# Contributing to M-Pesa iOS SDK

Thank you for your interest in contributing to the M-Pesa iOS SDK. This document provides guidelines and instructions for contributing.

## Code of Conduct

By participating in this project, you agree to maintain a respectful and inclusive environment for everyone.

## How to Contribute

### Reporting Bugs

1. Check if the bug has already been reported in [Issues](https://github.com/Huss3n/ios-mpesa-sdk/issues)
2. If not, create a new issue with:
   - Clear, descriptive title
   - Steps to reproduce
   - Expected vs actual behavior
   - iOS version, Xcode version, and device/simulator info
   - Code snippets if applicable

### Suggesting Features

1. Open an issue with the `enhancement` label
2. Describe the feature and its use case
3. Explain why it would benefit the SDK

### Pull Requests

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/your-feature`)
3. Make your changes
4. Write or update tests as needed
5. Ensure all tests pass and SwiftLint passes
6. Update documentation if applicable
7. Commit with clear, descriptive messages
8. Push to your fork
9. Open a Pull Request

## Development Setup

### Prerequisites

- macOS Ventura or later
- Xcode 15+
- Swift 5.9+
- SwiftLint (`brew install swiftlint`)

### Getting Started

```bash
# Clone your fork
git clone https://github.com/Huss3n/ios-mpesa-sdk.git

# Navigate to project
cd ios-mpesa-sdk

# Copy environment template and add your credentials
cp .env.example .env

# Open in Xcode
open Package.swift
```

### Running Tests

```bash
# Run all tests
swift test

# Or in Xcode: Cmd+U
```

### Running SwiftLint

```bash
# Check for issues
swiftlint

# Auto-fix issues where possible
swiftlint --fix
```

## Coding Standards

### Swift Style

- Follow [Swift API Design Guidelines](https://swift.org/documentation/api-design-guidelines/)
- Use meaningful, descriptive names
- Keep functions focused and concise
- Prefer value types (structs) over reference types (classes) where appropriate
- Run SwiftLint before committing

### File Headers

All Swift files should include the standard header:

```swift
//
//  FileName.swift
//  MpesaSDK
//
//  Created by [Author Name] on [Date].
//
```

### Documentation

- Add documentation comments for all public APIs
- Use `///` for documentation comments
- Include code examples where helpful

### Testing

- Write unit tests for new functionality
- Maintain or improve code coverage
- Mock external dependencies
- Integration tests require sandbox credentials in `.env`

## Commit Messages

- Use present tense ("Add feature" not "Added feature")
- Use imperative mood ("Move cursor to..." not "Moves cursor to...")
- Keep the first line under 72 characters
- Reference issues when applicable

## Versioning

We use [Semantic Versioning](https://semver.org/):

- **MAJOR**: Breaking API changes
- **MINOR**: New features (backwards compatible)
- **PATCH**: Bug fixes (backwards compatible)

To bump version:
```bash
./scripts/bump-version.sh patch  # or minor, major
```

## Review Process

1. All PRs require at least one review
2. Address review feedback promptly
3. Keep PRs focused and reasonably sized
4. Ensure CI passes before requesting review

## Questions?

Open an issue with the `question` label or reach out to the maintainers.

Thank you for contributing.
