# C2B (Customer to Business)

The C2B API enables your app to receive payment notifications when customers pay to your Paybill or Till number. Payments are initiated by customers via M-Pesa App, USSD, SIM Toolkit, or other channels.

## Table of Contents

- [Prerequisites](#prerequisites)
- [Setup](#setup)
- [Register Callback URLs](#register-callback-urls)
- [Simulate Transactions](#simulate-transactions)
- [Handle Callbacks](#handle-callbacks)
- [Validation Responses](#validation-responses)
- [Error Handling](#error-handling)
- [API Reference](#api-reference)

## Prerequisites

1. A [Daraja Developer Account](https://developer.safaricom.co.ke)
2. A sandbox app with Consumer Key and Consumer Secret
3. For production: a live M-Pesa Paybill or Till number

## Setup

Add the SDK to your project via Swift Package Manager:

```swift
// Package.swift
dependencies: [
    .package(url: "https://github.com/Huss3n/ios-mpesa-sdk.git", from: "1.0.0")
]
```

Initialize the SDK:

```swift
import MpesaSDK

// Sandbox (for testing)
let mpesa = Mpesa(
    consumerKey: "your_consumer_key",
    consumerSecret: "your_consumer_secret",
    environment: .sandbox
)

// Production (for live payments)
let mpesa = Mpesa(
    consumerKey: "your_consumer_key",
    consumerSecret: "your_consumer_secret",
    environment: .production
)
```

The SDK handles OAuth token management automatically. Tokens are cached and refreshed when they expire.

## Register Callback URLs

Before receiving payment notifications, you must register your callback URLs with M-Pesa. This tells M-Pesa where to send payment data.

- **Confirmation URL**: Receives a notification after every successful payment.
- **Validation URL**: Receives a request _before_ payment completion, allowing you to accept or reject it. Only called if external validation is enabled (disabled by default — contact apisupport@safaricom.co.ke to enable).

### Using Parameters

```swift
do {
    let response = try await mpesa.c2b.registerURLs(
        shortCode: "600984",
        responseType: .completed,
        confirmationURL: URL(string: "https://yourdomain.com/c2b/confirm")!,
        validationURL: URL(string: "https://yourdomain.com/c2b/validate")!
    )

    if response.isSuccessful {
        print("URLs registered: \(response.originatorConversationID)")
    }
} catch {
    print("Failed: \(error.localizedDescription)")
}
```

### Using a Request Object

```swift
let request = C2BRegisterURLRequest(
    shortCode: "600984",
    responseType: .completed,
    confirmationURL: URL(string: "https://yourdomain.com/c2b/confirm")!,
    validationURL: URL(string: "https://yourdomain.com/c2b/validate")!
)

let response = try await mpesa.c2b.registerURLs(request)
```

### Parameters

| Parameter | Type | Description |
|---|---|---|
| `shortCode` | `String` | Your Paybill or Till number (e.g. `"600984"`) |
| `responseType` | `C2BResponseType` | Default action when validation URL is unreachable |
| `confirmationURL` | `URL` | URL to receive payment confirmations |
| `validationURL` | `URL` | URL to receive validation requests |

### Response Type

| Value | Behavior |
|---|---|
| `.completed` | M-Pesa completes the transaction if your validation URL is unreachable |
| `.cancelled` | M-Pesa cancels the transaction if your validation URL is unreachable |

### Response: `C2BRegisterURLResponse`

| Property | Type | Description |
|---|---|---|
| `originatorConversationID` | `String` | Unique identifier for the request |
| `responseCode` | `String` | `"0"` or `"00000000"` indicates success |
| `responseDescription` | `String` | Status description (e.g. `"Success"`) |
| `isSuccessful` | `Bool` | Computed — `true` when response code is `0` |

### Important Notes

- **Sandbox**: You can register URLs multiple times or overwrite existing ones.
- **Production**: This is a one-time operation. To change URLs, delete them from the URL Management tab under Self-Service on the Daraja portal, then re-register.
- URLs must be publicly accessible. Production URLs must use HTTPS.
- Do not include keywords like "M-PESA", "Safaricom", "exec", "SQL" in your URLs.

## Simulate Transactions

Simulate a C2B payment in the sandbox environment for testing. This is **not available in production** — real payments come from customers via the M-Pesa App, USSD, or SIM Toolkit.

### PayBill Payment

```swift
do {
    let response = try await mpesa.c2b.simulate(
        shortCode: "600984",
        commandID: .customerPayBillOnline,
        amount: 100,
        msisdn: "254708374149",
        billRefNumber: "AccountRef123"
    )

    if response.isSuccessful {
        print("Simulation accepted: \(response.responseDescription)")
    }
} catch {
    print("Failed: \(error.localizedDescription)")
}
```

### Buy Goods (Till) Payment

```swift
let response = try await mpesa.c2b.simulate(
    shortCode: "600984",
    commandID: .customerBuyGoodsOnline,
    amount: 50,
    msisdn: "254708374149",
    billRefNumber: nil  // Not needed for Buy Goods
)
```

### Using a Request Object

```swift
let request = C2BSimulateRequest(
    shortCode: "600984",
    commandID: .customerPayBillOnline,
    amount: 200,
    msisdn: "254708374149",
    billRefNumber: "Invoice001"
)

let response = try await mpesa.c2b.simulate(request)
```

### Parameters

| Parameter | Type | Description |
|---|---|---|
| `shortCode` | `String` | Your Paybill or Till number |
| `commandID` | `C2BCommandID` | Transaction type |
| `amount` | `Int` | Amount in KES (whole numbers only) |
| `msisdn` | `String` | Phone number to debit (format: `254XXXXXXXXX`) |
| `billRefNumber` | `String?` | Account reference for PayBill. Use `nil` for Buy Goods |

### Command ID

| Value | Use Case |
|---|---|
| `.customerPayBillOnline` | Payment to a Paybill number |
| `.customerBuyGoodsOnline` | Payment to a Till number |

### Response: `C2BSimulateResponse`

| Property | Type | Description |
|---|---|---|
| `originatorConversationID` | `String` | Unique identifier for the request |
| `responseCode` | `String` | `"0"` indicates success |
| `responseDescription` | `String` | e.g. `"Accept the service request successfully."` |
| `isSuccessful` | `Bool` | Computed — `true` when response code is `0` |

## Handle Callbacks

After a successful C2B payment, M-Pesa sends a callback to your registered URLs. Use the SDK to parse the callback payload on your server.

### Parse a Callback

```swift
// In your server endpoint handler
let callbackData: Data = // ... raw JSON data from M-Pesa

do {
    let callback = try C2BService.parseCallback(from: callbackData)

    print("Transaction ID: \(callback.transID)")
    print("Amount: \(callback.transAmount)")
    print("Customer: \(callback.customerName)")
    print("Phone: \(callback.msisdn)")
    print("Short Code: \(callback.businessShortCode)")
    print("Reference: \(callback.billRefNumber)")

    // Use computed helpers
    if let amount = callback.amount {
        print("Parsed amount: \(amount)")  // Decimal
    }

    if let date = callback.transactionDate {
        print("Date: \(date)")  // Date
    }
} catch {
    print("Failed to parse callback: \(error)")
}
```

### Callback: `C2BCallback`

This is the payload M-Pesa sends to both your validation and confirmation URLs.

| Property | Type | Description |
|---|---|---|
| `transactionType` | `String` | `"Pay Bill"` or `"Buy Goods"` |
| `transID` | `String` | Unique M-Pesa transaction ID (e.g. `"RKL51ZDR4F"`) |
| `transTime` | `String` | Timestamp in `YYYYMMDDHHmmss` format |
| `transAmount` | `String` | Amount paid (e.g. `"500.00"`) |
| `businessShortCode` | `String` | Your Paybill or Till number |
| `billRefNumber` | `String` | Account reference (PayBill only) |
| `invoiceNumber` | `String` | Invoice number (if applicable) |
| `orgAccountBalance` | `String` | Balance after transaction (empty for validation) |
| `thirdPartyTransID` | `String` | Partner tracking ID |
| `msisdn` | `String` | Masked customer phone (e.g. `"2547 ***** 126"`) |
| `firstName` | `String` | Customer's first name |
| `middleName` | `String` | Customer's middle name |
| `lastName` | `String` | Customer's last name |

### Computed Properties

| Property | Type | Description |
|---|---|---|
| `customerName` | `String` | Full name (joins non-empty name parts) |
| `amount` | `Decimal?` | `transAmount` parsed as `Decimal` |
| `transactionDate` | `Date?` | `transTime` parsed as `Date` |

### Example Callback JSON

```json
{
  "TransactionType": "Pay Bill",
  "TransID": "RKL51ZDR4F",
  "TransTime": "20231121121325",
  "TransAmount": "500.00",
  "BusinessShortCode": "600966",
  "BillRefNumber": "Account123",
  "InvoiceNumber": "",
  "OrgAccountBalance": "25000.00",
  "ThirdPartyTransID": "",
  "MSISDN": "2547 ***** 126",
  "FirstName": "JOHN",
  "MiddleName": "DOE",
  "LastName": "SMITH"
}
```

## Validation Responses

If external validation is enabled on your shortcode, M-Pesa sends a validation request before completing the transaction. You must respond within ~8 seconds to accept or reject the payment.

### Accept a Transaction

```swift
let response = C2BValidationResponse.accept()
// Returns: { "ResultCode": "0", "ResultDesc": "Accepted" }
```

### Reject a Transaction

```swift
// Generic rejection with a specific code
let response = C2BValidationResponse.reject(
    code: .invalidAccountNumber,
    description: "Account not found"
)

// Convenience methods
let response = C2BValidationResponse.rejectInvalidMSISDN()
let response = C2BValidationResponse.rejectInvalidAccountNumber()
let response = C2BValidationResponse.rejectInvalidAmount()
```

### Rejection Codes

| Code | Enum Case | Customer Message |
|---|---|---|
| `C2B00011` | `.invalidMSISDN` | Invalid phone number |
| `C2B00012` | `.invalidAccountNumber` | Invalid account number |
| `C2B00013` | `.invalidAmount` | Invalid amount |
| `C2B00014` | `.invalidKYCDetails` | Invalid KYC details |
| `C2B00015` | `.invalidShortCode` | Invalid short code |
| `C2B00016` | `.otherError` | Other error |

### Server-Side Example

```swift
// In your server validation endpoint
func handleValidation(data: Data) -> C2BValidationResponse {
    do {
        let callback = try C2BService.parseCallback(from: data)

        // Validate the account number exists in your system
        guard isValidAccount(callback.billRefNumber) else {
            return C2BValidationResponse.rejectInvalidAccountNumber()
        }

        // Validate the amount
        guard let amount = callback.amount, amount >= 10 else {
            return C2BValidationResponse.rejectInvalidAmount()
        }

        return C2BValidationResponse.accept()
    } catch {
        return C2BValidationResponse.reject(
            code: .otherError,
            description: "Failed to process request"
        )
    }
}
```

## Error Handling

All SDK methods throw `MpesaError`. Handle specific cases to provide meaningful feedback to your users.

```swift
do {
    let response = try await mpesa.c2b.registerURLs(
        shortCode: "600984",
        responseType: .completed,
        confirmationURL: URL(string: "https://yourdomain.com/confirm")!,
        validationURL: URL(string: "https://yourdomain.com/validate")!
    )
} catch MpesaError.authenticationFailed(let message) {
    // Invalid consumer key/secret
    print("Auth failed: \(message)")
} catch MpesaError.apiError(let code, let message) {
    // M-Pesa API returned an error
    print("API error (\(code)): \(message)")
} catch MpesaError.networkError(let error) {
    // Network connectivity issue
    print("Network error: \(error.localizedDescription)")
} catch MpesaError.serverError(let statusCode, let message) {
    // HTTP error (e.g. 500, 403)
    print("Server error (\(statusCode)): \(message)")
} catch MpesaError.decodingError(let error) {
    // Unexpected response format
    print("Decoding error: \(error)")
} catch {
    print("Unexpected error: \(error)")
}
```

### Common Errors

| Error | Cause | Fix |
|---|---|---|
| `authenticationFailed` | Invalid or expired credentials | Check your consumer key and secret |
| `apiError("400.003.02", ...)` | Malformed request body | Verify all parameters match the expected format |
| `apiError("500.003.1001", "Urls are already registered")` | URLs already registered in production | Delete existing URLs from the Daraja portal, then re-register |
| `apiError("500.003.03", "Quota Violation")` | Too many requests per second | Add delays between requests |
| `serverError(403, ...)` | WAF/CDN blocking the request | Retry later, or check if your IP is blocked |
| `networkError` | No internet or timeout | Check connectivity, SDK uses 30-second timeout |

## API Reference

### Types

```
Mpesa                        — SDK entry point
  .c2b                       — C2BService instance

C2BService                   — C2B API operations
  .registerURLs(...)         — Register callback URLs
  .simulate(...)             — Simulate transaction (sandbox only)
  .parseCallback(from:)      — Parse callback JSON (static)

C2BRegisterURLRequest        — Register URL request model
C2BRegisterURLResponse       — Register URL response model
C2BSimulateRequest           — Simulate request model
C2BSimulateResponse          — Simulate response model
C2BCallback                  — Callback payload model
C2BValidationResponse        — Validation response builder

C2BResponseType              — .completed | .cancelled
C2BCommandID                 — .customerPayBillOnline | .customerBuyGoodsOnline
C2BTransactionType           — .payBill | .buyGoods
C2BValidationResultCode      — .accepted | .invalidMSISDN | .invalidAccountNumber | ...

MpesaError                   — SDK error type
MpesaConfiguration           — SDK configuration
MpesaEnvironment             — .sandbox | .production
```
