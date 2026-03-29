# B2C (Business to Customer)

The B2C API enables businesses to send payments from a B2C shortcode to customers' M-PESA numbers (Bulk Disbursements). Common use cases include salary payments, cashback, promotional payouts, loan disbursements, and financial withdrawals.

## Table of Contents

- [Prerequisites](#prerequisites)
- [Setup](#setup)
- [Send a Payment](#send-a-payment)
- [Handle Results](#handle-results)
- [Result Codes](#result-codes)
- [Error Handling](#error-handling)
- [API Reference](#api-reference)

## Prerequisites

1. A [Daraja Developer Account](https://developer.safaricom.co.ke)
2. A sandbox app with Consumer Key and Consumer Secret
3. An API operator (initiator) configured on the Daraja portal with the **ORG B2C API Initiator** role
4. A pre-encrypted security credential:
   - Encrypt your API operator password with the M-Pesa public certificate
   - **Sandbox**: Use the sandbox certificate from the Daraja portal
   - **Production**: Use the production certificate
5. For production: a Bulk Disbursement Account or a one-account shortcode (can receive and disburse)

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

## Send a Payment

Call `payment` to send money from your business shortcode to a customer's M-PESA number.

### Using Parameters

```swift
do {
    let response = try await mpesa.b2c.payment(
        originatorConversationID: "600997_Test_32et3241ed8yu",
        initiatorName: "testapi",
        securityCredential: "your_encrypted_credential",
        commandID: .businessPayment,
        amount: 100,
        partyA: "600992",
        partyB: "254705912645",
        remarks: "Payment for services",
        resultURL: URL(string: "https://yourdomain.com/b2c/result")!,
        queueTimeOutURL: URL(string: "https://yourdomain.com/b2c/timeout")!
    )

    if response.isSuccessful {
        // Request accepted for processing
        print("Conversation ID: \(response.conversationID)")
        print("Originator ID: \(response.originatorConversationID)")
    }
} catch {
    print("Payment failed: \(error.localizedDescription)")
}
```

### Using a Request Object

For full control over optional fields like `occasion`, use the `B2CRequest` object directly:

```swift
let request = B2CRequest(
    originatorConversationID: "600997_Salary_March2026",
    initiatorName: "testapi",
    securityCredential: "your_encrypted_credential",
    commandID: .salaryPayment,
    amount: 50000,
    partyA: "600992",
    partyB: "254705912645",
    remarks: "March 2026 salary",
    resultURL: URL(string: "https://yourdomain.com/b2c/result")!,
    queueTimeOutURL: URL(string: "https://yourdomain.com/b2c/timeout")!,
    occasion: "MonthlySalary"
)

let response = try await mpesa.b2c.payment(request)
```

### Parameters

| Parameter | Type | Description |
|---|---|---|
| `originatorConversationID` | `String` | Unique ID per request to prevent duplicate disbursements. Can be used to query transaction status |
| `initiatorName` | `String` | API operator username as set on the M-PESA portal |
| `securityCredential` | `String` | Encrypted credential of the API operator |
| `commandID` | `B2CCommandID` | Type of B2C transaction. Default: `.businessPayment` |
| `amount` | `Int` | Transaction amount in KES (min 10, max 250,000) |
| `partyA` | `String` | B2C organization shortcode (debit account) |
| `partyB` | `String` | Customer's mobile number (format: `254XXXXXXXXX`) |
| `remarks` | `String` | Additional info. 2–100 characters. Default: `"OK"` |
| `resultURL` | `URL` | URL to receive the transaction result |
| `queueTimeOutURL` | `URL` | URL for notification if the request times out |
| `occasion` | `String?` | Additional info. 1–100 characters (optional) |

### Command ID

| Value | Use Case |
|---|---|
| `.salaryPayment` | Salary payments. Supports registered and unregistered customers |
| `.businessPayment` | Normal business payment. Supports only registered customers |
| `.promotionPayment` | Promotional payment with a congratulatory notification. Supports only registered customers |

### Response: `B2CResponse`

| Property | Type | Description |
|---|---|---|
| `originatorConversationID` | `String` | Echoed back from the request |
| `conversationID` | `String` | Unique identifier assigned by M-PESA |
| `responseCode` | `String` | `"0"` indicates the request was accepted |
| `responseDescription` | `String` | Status description |
| `isSuccessful` | `Bool` | Computed — `true` when response code is `0` |

### Important Notes

- A successful response means M-PESA **accepted the request** — not that the payment is complete. The actual result arrives via the `ResultURL` callback.
- The `originatorConversationID` must be unique per request to avoid duplicate disbursements. You can use it to query transaction status.
- The `conversationID` uniquely identifies this transaction on M-PESA's side. Store it to match with the result callback.
- B2C transactions debit the **Utility account**, not the MMF/Working account. Ensure sufficient funds are in the Utility account.
- The security credential can be reused across multiple requests — you do not need to re-encrypt for every call.

## Handle Results

After M-PESA processes the transaction, it sends a result to your `ResultURL`. The result contains detailed transaction information on success, or an error description on failure.

### Parse a Result

```swift
// In your server endpoint handler
let resultData: Data = // ... raw JSON data from M-Pesa

do {
    let result = try B2CService.parseResult(from: resultData)

    if result.isSuccessful {
        print("Receipt: \(result.transactionReceipt ?? "")")
        print("Amount: \(result.transactionAmount ?? 0)")
        print("Receiver: \(result.receiverPartyPublicName ?? "")")
        print("Completed: \(result.transactionCompletedDateTime ?? "")")
        print("Registered: \(result.b2cRecipientIsRegisteredCustomer ?? "")")
        print("Utility balance: \(result.b2cUtilityAccountAvailableFunds ?? 0)")
        print("Working balance: \(result.b2cWorkingAccountAvailableFunds ?? 0)")
    } else {
        print("Payment failed (\(result.resultCode)): \(result.resultDesc)")

        if result.resultCodeEnum == .insufficientBalance {
            print("Top up the B2C utility account")
        }
    }
} catch {
    print("Failed to parse result: \(error)")
}
```

### Result: `B2CResult`

| Property | Type | Description |
|---|---|---|
| `resultCode` | `Int` | `0` for success |
| `resultDesc` | `String` | Human-readable result description |
| `originatorConversationID` | `String` | Matches the request's originator conversation ID |
| `conversationID` | `String` | Matches the request's conversation ID |
| `transactionID` | `String` | Unique M-Pesa transaction ID (also sent to customer via SMS) |
| `resultParameters` | `[ResultParameter]?` | Transaction details (only on success) |
| `referenceData` | `[ReferenceItem]?` | Reference data items |
| `isSuccessful` | `Bool` | Computed — `true` when `resultCode == 0` |
| `resultCodeEnum` | `B2CResultCode?` | Typed enum if it matches a known code |

### Computed Helpers (from Result Parameters)

These are only available on successful results (`resultParameters` is `nil` on failure):

| Property | Type | Description |
|---|---|---|
| `transactionAmount` | `Double?` | Transaction amount |
| `transactionReceipt` | `String?` | M-Pesa receipt ID |
| `receiverPartyPublicName` | `String?` | Receiver's name and phone number |
| `transactionCompletedDateTime` | `String?` | Completion timestamp (e.g. `"06.07.2024 22:48:52"`) |
| `b2cUtilityAccountAvailableFunds` | `Double?` | Utility account balance |
| `b2cWorkingAccountAvailableFunds` | `Double?` | Working account balance |
| `b2cRecipientIsRegisteredCustomer` | `String?` | `"Y"` or `"N"` |
| `b2cChargesPaidAccountAvailableFunds` | `Double?` | Charges paid account balance |

### Example Result JSON (Success)

```json
{
    "Result": {
        "ResultType": 0,
        "ResultCode": 0,
        "ResultDesc": "The service request is processed successfully.",
        "OriginatorConversationID": "53e3-4aa8-9fe0-8fb5e4092cdd3533373",
        "ConversationID": "AG_20240706_2010364430d9bbdaf872",
        "TransactionID": "SG632NMUAB",
        "ResultParameters": {
            "ResultParameter": [
                { "Key": "TransactionAmount", "Value": 10 },
                { "Key": "TransactionReceipt", "Value": "SG632NMUAB" },
                { "Key": "ReceiverPartyPublicName", "Value": "254705912645 - NICHOLAS JOHN SONGOK" },
                { "Key": "TransactionCompletedDateTime", "Value": "06.07.2024 22:48:52" },
                { "Key": "B2CUtilityAccountAvailableFunds", "Value": 8959269.60 },
                { "Key": "B2CWorkingAccountAvailableFunds", "Value": 1199371.00 },
                { "Key": "B2CRecipientIsRegisteredCustomer", "Value": "Y" },
                { "Key": "B2CChargesPaidAccountAvailableFunds", "Value": -1980.00 }
            ]
        },
        "ReferenceData": {
            "ReferenceItem": {
                "Key": "QueueTimeoutURL",
                "Value": "https://internalsandbox.safaricom.co.ke/mpesa/b2cresults/v1/submit"
            }
        }
    }
}
```

### Example Result JSON (Failure)

```json
{
    "Result": {
        "ResultType": 0,
        "ResultCode": 2001,
        "ResultDesc": "The initiator information is invalid.",
        "OriginatorConversationID": "53e3-4aa8-9fe0-8fb5e4092cdd3544366",
        "ConversationID": "AG_20240707_201062f6f6f5804f7a33",
        "TransactionID": "SG722NMVXQ",
        "ReferenceData": {
            "ReferenceItem": {
                "Key": "QueueTimeoutURL",
                "Value": "https://internalsandbox.safaricom.co.ke/mpesa/b2cresults/v1/submit"
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

## Result Codes

| Code | Enum Case | Meaning |
|------|-----------|---------|
| 0 | `.success` | Transaction completed successfully |
| 1 | `.insufficientBalance` | Insufficient balance in B2C utility account |
| 2 | `.belowMinimumAmount` | Amount below minimum allowed |
| 3 | `.exceedsMaxAmount` | Amount exceeds maximum transaction limit |
| 4 | `.exceedsDailyLimit` | Amount exceeds daily transfer limit |
| 8 | `.exceedsMaxBalance` | Would exceed maximum customer account balance |
| 11 | `.debitPartyInvalidState` | B2C account is not active |
| 21 | `.initiatorNotAllowed` | API user lacks ORG B2C API initiator role |
| 2001 | `.invalidInitiatorInfo` | Invalid API user credentials |
| 2006 | `.accountStatusNotAllowed` | Account status does not allow this transaction |
| 2028 | `.notPermittedByProductAssignment` | Shortcode has no B2C permission |
| 2040 | `.customerTypeNotSupported` | Customer is not registered on M-PESA |
| 8006 | `.securityCredentialLocked` | API user password is locked |

All codes are available as `B2CResultCode` enum values:

```swift
switch result.resultCodeEnum {
case .success:
    // Process the payment
case .insufficientBalance:
    // Top up the B2C utility account
case .invalidInitiatorInfo:
    // Check API user credentials and encryption
case .customerTypeNotSupported:
    // Customer is not registered on M-PESA
default:
    print("Error \(result.resultCode): \(result.resultDesc)")
}
```

## Error Handling

All SDK methods throw `MpesaError`. Handle specific cases to provide meaningful feedback:

```swift
do {
    let response = try await mpesa.b2c.payment(
        originatorConversationID: "unique_id",
        initiatorName: "testapi",
        securityCredential: "your_encrypted_credential",
        amount: 100,
        partyA: "600992",
        partyB: "254705912645",
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
| `apiError("500.002.1001", ...)` | Duplicate OriginatorConversationID | Use a unique ID for each request |
| `apiError("500.001.1001", ...)` | Invalid initiator | Verify your initiator name on the Daraja portal |
| `apiError("500.001.1002", ...)` | Invalid security credential | Re-encrypt with the correct M-Pesa certificate |
| `serverError(403, ...)` | WAF/CDN blocking the request | Retry later, or check if your IP is blocked |
| `networkError` | No internet or timeout | Check connectivity, SDK uses 30-second timeout |

## API Reference

### Types

```
Mpesa                        — SDK entry point
  .b2c                       — B2CService instance

B2CService                   — B2C API operations
  .payment(...)              — Send payment to customer
  .parseResult(from:)        — Parse result callback JSON (static)

B2CRequest                   — Payment request model
B2CResponse                  — Acceptance response model
B2CResult                    — Async result callback model
  .ReferenceItem             — Reference data item

B2CCommandID                 — .salaryPayment | .businessPayment | .promotionPayment
B2CResultCode                — .success | .insufficientBalance | .invalidInitiatorInfo | ...

ResultParameter              — Key-value parameter (shared type)
AnyCodableValue              — Type-erased value: String, Int, or Double (shared type)

MpesaError                   — SDK error type
MpesaConfiguration           — SDK configuration
MpesaEnvironment             — .sandbox | .production
```
