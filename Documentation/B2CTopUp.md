# B2C Account Top Up

B2C Account Top Up loads funds into a B2C shortcode utility account for disbursement. Money moves from your MMF/Working account to a recipient's utility account. Unlike STK Push or C2B, the API response only confirms acceptance — the actual transaction result arrives asynchronously via a callback to your `ResultURL`.

## Table of Contents

- [Prerequisites](#prerequisites)
- [Setup](#setup)
- [Initiate a Top Up](#initiate-a-top-up)
- [Handle Results](#handle-results)
- [Error Handling](#error-handling)
- [API Reference](#api-reference)

## Prerequisites

1. A [Daraja Developer Account](https://developer.safaricom.co.ke)
2. A sandbox app with Consumer Key and Consumer Secret
3. An API operator (initiator) configured on the Daraja portal
4. A pre-encrypted security credential:
   - Encrypt your API operator password with the M-Pesa public certificate
   - **Sandbox**: Use the sandbox certificate from the Daraja portal
   - **Production**: Use the production certificate

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

// Production (for live transactions)
let mpesa = Mpesa(
    consumerKey: "your_consumer_key",
    consumerSecret: "your_consumer_secret",
    environment: .production
)
```

The SDK handles OAuth token management automatically. Tokens are cached and refreshed when they expire.

## Initiate a Top Up

Call `topUp` to load funds into a B2C shortcode utility account.

### Using Parameters

```swift
do {
    let response = try await mpesa.b2cTopUp.topUp(
        initiator: "testapi",
        securityCredential: "your_encrypted_credential",
        partyA: "600984",
        partyB: "600000",
        amount: 239,
        accountReference: "353353",
        resultURL: URL(string: "https://yourdomain.com/b2c/result")!,
        queueTimeOutURL: URL(string: "https://yourdomain.com/b2c/timeout")!
    )

    if response.isSuccessful {
        // Request accepted for processing
        print("Conversation ID: \(response.conversationID)")
        print("Originator ID: \(response.originatorConversationID)")
    }
} catch {
    print("Top up failed: \(error.localizedDescription)")
}
```

### Using a Request Object

For full control over optional fields like `requester` and `remarks`, use the `B2CTopUpRequest` object directly:

```swift
let request = B2CTopUpRequest(
    initiator: "testapi",
    securityCredential: "your_encrypted_credential",
    partyA: "600984",
    partyB: "600000",
    amount: 500,
    accountReference: "353353",
    resultURL: URL(string: "https://yourdomain.com/b2c/result")!,
    queueTimeOutURL: URL(string: "https://yourdomain.com/b2c/timeout")!,
    requester: "254722000000",
    remarks: "Load B2C float"
)

let response = try await mpesa.b2cTopUp.topUp(request)
```

### Parameters

| Parameter | Type | Description |
|---|---|---|
| `initiator` | `String` | API operator name as set on the Daraja portal |
| `securityCredential` | `String` | Encrypted credential of the API operator |
| `partyA` | `String` | Organization's shortcode (debit account) |
| `partyB` | `String` | Organization's shortcode (credit account) |
| `amount` | `Int` | Transaction amount in KES |
| `accountReference` | `String` | Account reference for the recipient |
| `resultURL` | `URL` | URL to receive the transaction result |
| `queueTimeOutURL` | `URL` | URL to receive notification if the request times out |
| `requester` | `String?` | Phone number of the requester (optional) |
| `remarks` | `String?` | Comments about the transaction. Max 100 characters (optional, defaults to `"OK"`) |

### Fixed Fields

The SDK automatically sets these fields in the API request:

| Field | Value | Description |
|---|---|---|
| `CommandID` | `"BusinessPayToBulk"` | B2C top up command type |
| `SenderIdentifierType` | `"4"` | Shortcode identifier type |
| `RecieverIdentifierType` | `"4"` | Shortcode identifier type |

### Response: `B2CTopUpResponse`

| Property | Type | Description |
|---|---|---|
| `originatorConversationID` | `String` | Unique identifier for the originator's conversation |
| `conversationID` | `String` | Unique identifier for the conversation |
| `responseCode` | `String` | `"0"` indicates the request was accepted |
| `responseDescription` | `String` | Status description |
| `isSuccessful` | `Bool` | Computed — `true` when response code is `0` |

### Important Notes

- A successful response means M-Pesa **accepted the request** — not that the top up is complete. The actual result arrives via the `ResultURL` callback.
- The `conversationID` uniquely identifies this transaction. Store it to match with the result callback.
- The `Amount` is sent as a String to the API (e.g. `"239"` not `239`), matching Daraja's specification. The SDK handles this conversion automatically.

## Handle Results

After M-Pesa processes the transaction, it sends a result to your `ResultURL`. The result contains detailed transaction information on success, or an error description on failure.

### Parse a Result

```swift
// In your server endpoint handler
let resultData: Data = // ... raw JSON data from M-Pesa

do {
    let result = try B2CTopUpService.parseResult(from: resultData)

    if result.isSuccessful {
        print("Transaction ID: \(result.transactionID)")
        print("Amount: \(result.amount ?? 0)")
        print("Receipt: \(result.transactionReceipt ?? "")")
        print("Currency: \(result.currency ?? "")")
        print("Completed: \(result.transCompletedTime ?? "")")
        print("Receiver: \(result.receiverPartyPublicName ?? "")")
        print("Charges: \(result.debitPartyCharges ?? "")")
    } else {
        print("Top up failed (\(result.resultCode)): \(result.resultDesc)")
    }
} catch {
    print("Failed to parse result: \(error)")
}
```

### Result: `B2CTopUpResult`

| Property | Type | Description |
|---|---|---|
| `resultCode` | `Int` | `0` for success |
| `resultDesc` | `String` | Human-readable result description |
| `originatorConversationID` | `String` | Matches the request's originator conversation ID |
| `conversationID` | `String` | Matches the request's conversation ID |
| `transactionID` | `String` | Unique M-Pesa transaction ID |
| `resultParameters` | `[ResultParameter]?` | Transaction details (only on success) |
| `referenceData` | `[ReferenceItem]?` | Reference data items |
| `isSuccessful` | `Bool` | Computed — `true` when `resultCode == 0` |

### Computed Helpers (from Result Parameters)

These are only available on successful results (`resultParameters` is `nil` on failure):

| Property | Type | Description |
|---|---|---|
| `amount` | `Double?` | Transaction amount |
| `transactionReceipt` | `String?` | M-Pesa receipt ID |
| `transCompletedTime` | `String?` | Completion timestamp (e.g. `"20240710101835"`) |
| `receiverPartyPublicName` | `String?` | Receiver's public name |
| `currency` | `String?` | Transaction currency (e.g. `"KES"`) |
| `debitPartyCharges` | `String?` | Charges breakdown (e.g. `"Fee For B2C Payment\|KES\|2.63"`) |

### Example Result JSON (Success)

```json
{
    "Result": {
        "ResultType": 0,
        "ResultCode": 0,
        "ResultDesc": "The service request is processed successfully.",
        "OriginatorConversationID": "2dfa-bb89-c62e4133280d71011",
        "ConversationID": "AG_20240710_2010325b025970fbc403",
        "TransactionID": "SBL2G50CB3",
        "ResultParameters": {
            "ResultParameter": [
                { "Key": "DebitPartyName", "Value": "600984 - Safcom" },
                { "Key": "CreditPartyName", "Value": "600000 - Safcom" },
                { "Key": "Amount", "Value": 239 },
                { "Key": "DebitPartyCharges", "Value": "Fee For B2C Payment|KES|2.63" },
                { "Key": "TransCompletedTime", "Value": "20240710101835" },
                { "Key": "TransactionReceipt", "Value": "SBL2G50CB3" },
                { "Key": "Currency", "Value": "KES" }
            ]
        },
        "ReferenceData": {
            "ReferenceItem": [
                { "Key": "QueueTimeoutURL", "Value": "https://example.com/timeout" },
                { "Key": "Occasion" }
            ]
        }
    }
}
```

### Example Result JSON (Failure)

When the transaction fails, `ResultParameters` may be absent or contain a single item instead of an array. The SDK handles both formats automatically.

```json
{
    "Result": {
        "ResultType": 0,
        "ResultCode": 2001,
        "ResultDesc": "The initiator information is invalid.",
        "OriginatorConversationID": "fail-orig-id",
        "ConversationID": "AG_fail",
        "TransactionID": "SBL0000000",
        "ReferenceData": {
            "ReferenceItem": {
                "Key": "QueueTimeoutURL",
                "Value": "https://example.com/timeout"
            }
        }
    }
}
```

### Flexible Decoding

The SDK handles several Daraja API quirks in the result callback:

- **`ResultCode`** can be an Int (`0`) or a String (`"0"`) — both are decoded correctly
- **`ResultParameter`** can be an array (success) or a single object (failure) — both are decoded as `[ResultParameter]`
- **`ReferenceItem`** can be an array or a single object — both are decoded as `[ReferenceItem]`
- **`ReferenceItem.Value`** is optional — some items have only a `Key` with no value

## Error Handling

All SDK methods throw `MpesaError`. Handle specific cases to provide meaningful feedback:

```swift
do {
    let response = try await mpesa.b2cTopUp.topUp(
        initiator: "testapi",
        securityCredential: "your_encrypted_credential",
        partyA: "600984",
        partyB: "600000",
        amount: 239,
        accountReference: "353353",
        resultURL: URL(string: "https://yourdomain.com/b2c/result")!,
        queueTimeOutURL: URL(string: "https://yourdomain.com/b2c/timeout")!
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
} catch {
    print("Unexpected error: \(error)")
}
```

### Common Errors

| Error | Cause | Fix |
|---|---|---|
| `authenticationFailed` | Invalid or expired credentials | Check your consumer key and secret |
| `apiError("500.001.1001", ...)` | Invalid initiator | Verify your initiator name on the Daraja portal |
| `apiError("500.001.1002", ...)` | Invalid security credential | Re-encrypt with the correct M-Pesa certificate |
| `apiError("500.003.02", ...)` | System is busy | Retry after a few minutes |
| `serverError(403, ...)` | WAF/CDN blocking the request | Retry later, or check if your IP is blocked |
| `networkError` | No internet or timeout | Check connectivity, SDK uses 30-second timeout |

### Result Error Codes

| Code | Meaning |
|------|---------|
| 0 | Transaction completed successfully |
| 2001 | The initiator information is invalid |
| 2006 | Insufficient funds in the debit account |
| 2025 | Receiver is not authorized to receive funds |

## API Reference

### Types

```
Mpesa                        — SDK entry point
  .b2cTopUp                  — B2CTopUpService instance

B2CTopUpService              — B2C Account Top Up API operations
  .topUp(...)                — Initiate a top up request
  .parseResult(from:)        — Parse result callback JSON (static)

B2CTopUpRequest              — Top up request model
B2CTopUpResponse             — Acceptance response model
B2CTopUpResult               — Async result callback model
  .ReferenceItem             — Reference data item

ResultParameter              — Key-value parameter (shared type)
AnyCodableValue              — Type-erased value: String, Int, or Double (shared type)

MpesaError                   — SDK error type
MpesaConfiguration           — SDK configuration
MpesaEnvironment             — .sandbox | .production
```
