# M-Pesa iOS SDK

A native Swift SDK for integrating Safaricom's M-Pesa Daraja API into iOS applications.

## Overview

This SDK provides a modern, type-safe interface for M-Pesa payment integration on iOS. Built with Swift Concurrency, protocol-oriented design, and following Apple's best practices.

## Features

- **STK Push (Lipa Na M-Pesa)** - Initiate payment prompts on customer phones
- **C2B (Customer to Business)** - Register callback URLs and receive payment notifications
- **B2C (Business to Customer)** - Send payments to customer M-PESA numbers (Bulk Disbursements)
- **B2C Account Top Up** - Load funds into B2C shortcode utility accounts
- OAuth 2.0 authentication with automatic token management
- Sandbox and Production environment support
- Async/await API design
- Type-safe request and response models
- Comprehensive error handling

## Requirements

- iOS 15.0+ / macOS 12.0+
- Swift 5.9+
- Xcode 15+

## Installation

### Swift Package Manager

Add the following to your `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/Huss3n/ios-mpesa-sdk.git", from: "1.0.0")
]
```

Or in Xcode: **File → Add Package Dependencies** → Enter repository URL

## Quick Start

```swift
import MpesaSDK

// Initialize the SDK
let mpesa = Mpesa(
    consumerKey: "your_consumer_key",
    consumerSecret: "your_consumer_secret",
    environment: .sandbox
)
```

## C2B (Customer to Business)

The C2B API enables merchants to receive notifications for payments to their Paybill or Till numbers.

### Register Callback URLs

```swift
do {
    let response = try await mpesa.c2b.registerURLs(
        shortCode: "600984",
        responseType: .completed,
        confirmationURL: URL(string: "https://example.com/confirm")!,
        validationURL: URL(string: "https://example.com/validate")!
    )

    if response.isSuccessful {
        print("URLs registered successfully")
    }
} catch {
    print("Registration failed: \(error)")
}
```

### Simulate Transaction (Sandbox Only)

```swift
do {
    let response = try await mpesa.c2b.simulate(
        shortCode: "600984",
        commandID: .customerPayBillOnline,
        amount: 100,
        msisdn: "254708374149",
        billRefNumber: "AccountRef123"
    )

    print("Simulation: \(response.responseDescription)")
} catch {
    print("Simulation failed: \(error)")
}
```

### Handle Callbacks (Server-side)

Parse incoming M-Pesa callbacks:

```swift
// In your server endpoint handler
let callbackData: Data = // ... received from M-Pesa

do {
    let callback = try C2BService.parseCallback(from: callbackData)

    print("Transaction ID: \(callback.transID)")
    print("Amount: \(callback.transAmount)")
    print("Customer: \(callback.customerName)")
} catch {
    print("Failed to parse callback: \(error)")
}
```

### Validation Response

If you have external validation enabled, respond to validation requests:

```swift
// Accept the transaction
let acceptResponse = C2BValidationResponse.accept()

// Or reject with a reason
let rejectResponse = C2BValidationResponse.rejectInvalidAccountNumber()
```

## B2C (Business to Customer)

The B2C API enables businesses to send payments to customers' M-PESA numbers (Bulk Disbursements).

### Send a Payment

```swift
do {
    let response = try await mpesa.b2c.payment(
        originatorConversationID: "unique_request_id",
        initiatorName: "testapi",
        securityCredential: "your_encrypted_credential",
        commandID: .businessPayment,
        amount: 100,
        partyA: "600992",
        partyB: "254705912645",
        resultURL: URL(string: "https://example.com/b2c/result")!,
        queueTimeOutURL: URL(string: "https://example.com/b2c/timeout")!
    )

    if response.isSuccessful {
        print("Request accepted: \(response.conversationID)")
    }
} catch {
    print("Payment failed: \(error)")
}
```

### Handle Result Callbacks

```swift
let resultData: Data = // ... received from M-Pesa

do {
    let result = try B2CService.parseResult(from: resultData)

    if result.isSuccessful {
        print("Receipt: \(result.transactionReceipt ?? "")")
        print("Amount: \(result.transactionAmount ?? 0)")
        print("Receiver: \(result.receiverPartyPublicName ?? "")")
    } else {
        print("Failed (\(result.resultCode)): \(result.resultDesc)")
    }
} catch {
    print("Failed to parse result: \(error)")
}
```

## Error Handling

```swift
do {
    let response = try await mpesa.c2b.registerURLs(...)
} catch MpesaError.authenticationFailed(let message) {
    print("Auth failed: \(message)")
} catch MpesaError.apiError(let code, let message) {
    print("API error (\(code)): \(message)")
} catch MpesaError.networkError(let error) {
    print("Network error: \(error)")
} catch {
    print("Unexpected error: \(error)")
}
```

## Documentation

- [Safaricom Daraja API Documentation](https://developer.safaricom.co.ke/APIs)
- [M-Pesa Developer Portal](https://developer.safaricom.co.ke/)

## Contributing

Please read [CONTRIBUTING.md](CONTRIBUTING.md) for details on our code of conduct and the process for submitting pull requests.

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.
