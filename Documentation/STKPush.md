# STK Push (Lipa Na M-Pesa)

STK Push is the "Pay with M-Pesa" experience. Your app sends a request to M-Pesa, and the customer receives a payment prompt (USSD push) on their phone. Once they enter their PIN, M-Pesa processes the payment and sends a callback with the result. This is a merchant-initiated flow — unlike C2B where the customer initiates the payment.

## Table of Contents

- [Prerequisites](#prerequisites)
- [Setup](#setup)
- [Initiate a Payment](#initiate-a-payment)
- [Handle Callbacks](#handle-callbacks)
- [Result Codes](#result-codes)
- [Error Handling](#error-handling)
- [API Reference](#api-reference)

## Prerequisites

1. A [Daraja Developer Account](https://developer.safaricom.co.ke)
2. A sandbox app with Consumer Key and Consumer Secret
3. Your Lipa Na M-Pesa passkey:
   - **Sandbox**: Use the standard test passkey (available on the Daraja API test page)
   - **Production**: Sent to your developer email after go-live approval

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

## Initiate a Payment

Call `initiatePayment` to send a payment prompt to a customer's phone.

### Using Parameters

```swift
do {
    let response = try await mpesa.stkPush.initiatePayment(
        businessShortCode: "174379",
        passKey: "your_passkey",
        amount: 100,
        phoneNumber: "254722000000",
        callbackURL: URL(string: "https://yourdomain.com/stk/callback")!,
        accountReference: "Order001"
    )

    if response.isSuccessful {
        // Payment prompt sent to customer's phone
        print("Checkout ID: \(response.checkoutRequestID)")
        print("Merchant ID: \(response.merchantRequestID)")
    }
} catch {
    print("STK Push failed: \(error.localizedDescription)")
}
```

### Using a Request Object

For full control over the transaction type and description, use the `STKPushRequest` object directly:

```swift
let request = STKPushRequest(
    businessShortCode: "174379",
    passKey: "your_passkey",
    amount: 500,
    phoneNumber: "254722000000",
    callbackURL: URL(string: "https://yourdomain.com/stk/callback")!,
    accountReference: "Invoice42",
    transactionDesc: "Shoes",
    transactionType: .customerBuyGoodsOnline
)

let response = try await mpesa.stkPush.initiatePayment(request)
```

### Parameters

| Parameter | Type | Description |
|---|---|---|
| `businessShortCode` | `String` | Your Paybill or Till number (e.g. `"174379"`) |
| `passKey` | `String` | Lipa Na M-Pesa passkey from Safaricom |
| `amount` | `Int` | Transaction amount in KES |
| `phoneNumber` | `String` | Phone number to receive the prompt (format: `254XXXXXXXXX`) |
| `callbackURL` | `URL` | URL to receive the transaction result |
| `accountReference` | `String` | Reference shown in the USSD prompt. Max 12 characters |
| `transactionDesc` | `String` | Description of the transaction. Max 13 characters. Default: `"Payment"` |
| `transactionType` | `STKPushTransactionType` | `.customerPayBillOnline` (default) or `.customerBuyGoodsOnline` |

### Transaction Type

| Value | Use Case |
|---|---|
| `.customerPayBillOnline` | Payment to a Paybill number (default) |
| `.customerBuyGoodsOnline` | Payment to a Till number |

### Password and Timestamp

The Daraja API requires a `Password` field (`base64(Shortcode + Passkey + Timestamp)`) and a `Timestamp` in `YYYYMMDDHHmmss` format. The SDK generates both automatically from your `businessShortCode` and `passKey` — you never need to handle this yourself.

### Response: `STKPushResponse`

| Property | Type | Description |
|---|---|---|
| `merchantRequestID` | `String` | Unique identifier for the merchant request |
| `checkoutRequestID` | `String` | Unique identifier for the checkout request. Use this to track the transaction |
| `responseCode` | `String` | `"0"` indicates the request was accepted for processing |
| `responseDescription` | `String` | Status description |
| `customerMessage` | `String` | Customer-facing message from M-Pesa |
| `isSuccessful` | `Bool` | Computed — `true` when response code is `0` |

### Important Notes

- A successful response means M-Pesa **accepted the request** — not that the payment is complete. The actual payment result arrives via the callback.
- The `checkoutRequestID` uniquely identifies this payment attempt. Store it to match with the callback.
- The customer has about 60 seconds to enter their PIN before the request expires (result code `1019`).
- Avoid sending duplicate requests for the same amount and phone number within 2 minutes (result code `17`).

## Handle Callbacks

After the customer completes (or cancels) the payment, M-Pesa sends a callback to your `callbackURL`. The callback has a nested JSON structure that the SDK parses for you.

### Parse a Callback

```swift
// In your server endpoint handler
let callbackData: Data = // ... raw JSON data from M-Pesa

do {
    let callback = try STKPushService.parseCallback(from: callbackData)

    if callback.isSuccessful {
        print("Receipt: \(callback.mpesaReceiptNumber ?? "")")
        print("Amount: \(callback.amount ?? 0)")
        print("Phone: \(callback.phoneNumber ?? 0)")
        print("Date: \(callback.transactionDate ?? 0)")
    } else {
        print("Payment failed: \(callback.resultDesc)")

        // Check the specific reason
        if callback.resultCodeEnum == .cancelledByUser {
            print("Customer cancelled the payment")
        }
    }
} catch {
    print("Failed to parse callback: \(error)")
}
```

### Callback: `STKPushCallback`

| Property | Type | Description |
|---|---|---|
| `merchantRequestID` | `String` | Matches the request's merchant ID |
| `checkoutRequestID` | `String` | Matches the request's checkout ID |
| `resultCode` | `Int` | `0` for success, see [Result Codes](#result-codes) for others |
| `resultDesc` | `String` | Human-readable result description |
| `callbackMetadata` | `[CallbackItem]?` | Metadata items (only present on success) |
| `isSuccessful` | `Bool` | Computed — `true` when `resultCode == 0` |
| `resultCodeEnum` | `STKPushResultCode?` | Typed enum if it matches a known code |

### Computed Helpers (from Callback Metadata)

These are only available on successful callbacks (`callbackMetadata` is `nil` on failure):

| Property | Type | Description |
|---|---|---|
| `amount` | `Double?` | Transaction amount |
| `mpesaReceiptNumber` | `String?` | M-Pesa receipt (e.g. `"NLJ7RT61SV"`) |
| `transactionDate` | `Int?` | Timestamp as integer (`YYYYMMDDHHmmss`) |
| `phoneNumber` | `Int?` | Phone number that paid |

### Example Callback JSON (Success)

```json
{
    "Body": {
        "stkCallback": {
            "MerchantRequestID": "29115-34620561-1",
            "CheckoutRequestID": "ws_CO_191220191020363925",
            "ResultCode": 0,
            "ResultDesc": "The service request is processed successfully.",
            "CallbackMetadata": {
                "Item": [
                    { "Name": "Amount", "Value": 1.00 },
                    { "Name": "MpesaReceiptNumber", "Value": "NLJ7RT61SV" },
                    { "Name": "TransactionDate", "Value": 20191219102115 },
                    { "Name": "PhoneNumber", "Value": 254708374149 }
                ]
            }
        }
    }
}
```

### Example Callback JSON (Failure)

When the customer cancels or the request fails, the callback has no `CallbackMetadata`:

```json
{
    "Body": {
        "stkCallback": {
            "MerchantRequestID": "f1e2-4b95-a71d-b30d3cdbb7a7942864",
            "CheckoutRequestID": "ws_CO_21072024125243250722943992",
            "ResultCode": 1032,
            "ResultDesc": "Request cancelled by user"
        }
    }
}
```

## Result Codes

| Code | Enum Case | Meaning |
|------|-----------|---------|
| 0 | `.success` | Transaction completed successfully |
| 1 | `.insufficientBalance` | Insufficient balance in the account |
| 2 | `.belowMinimumAmount` | Amount is below minimum allowed |
| 3 | `.exceedsMaxAmount` | Amount exceeds maximum transaction limit |
| 4 | `.exceedsDailyLimit` | Amount exceeds daily transaction limit |
| 17 | `.duplicateRequest` | Duplicate request — wait 2 minutes between same amount/customer |
| 1019 | `.transactionExpired` | Transaction expired before user responded |
| 1025 | `.ussdPromptTooLong` | USSD prompt too long (`accountReference` too long) |
| 1032 | `.cancelledByUser` | User cancelled the transaction |
| 1037 | `.phoneUnreachable` | Phone is unreachable |
| 2001 | `.wrongPin` | User entered wrong PIN |
| 2028 | `.wrongTransactionType` | Wrong `TransactionType` or `PartyB` mismatch |

All codes are available as `STKPushResultCode` enum values. You can match them in your callback handler:

```swift
switch callback.resultCodeEnum {
case .success:
    // Process the payment
case .cancelledByUser:
    // Show "Payment cancelled" to merchant
case .transactionExpired:
    // Prompt customer to try again
case .insufficientBalance:
    // Inform about insufficient funds
default:
    print("Error \(callback.resultCode): \(callback.resultDesc)")
}
```

## Error Handling

All SDK methods throw `MpesaError`. Handle specific cases to provide meaningful feedback:

```swift
do {
    let response = try await mpesa.stkPush.initiatePayment(
        businessShortCode: "174379",
        passKey: "your_passkey",
        amount: 100,
        phoneNumber: "254722000000",
        callbackURL: URL(string: "https://yourdomain.com/stk/callback")!,
        accountReference: "Order001"
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

### Common API Errors

| Error Code | Meaning | Fix |
|---|---|---|
| `500.001.1001` | Merchant does not exist | Verify your `businessShortCode` is correct for STK Push |
| `500.001.1002` | Invalid passkey | Check your Lipa Na M-Pesa passkey |
| `500.003.02` | System is busy | Retry after a few minutes |
| `400.002.02` | Bad request — invalid `PhoneNumber` | Use format `254XXXXXXXXX` (no `+` or leading `0`) |
| `404.001.04` | Invalid `CallBackURL` | Ensure URL is valid and publicly accessible |

## API Reference

### Types

```
Mpesa                        — SDK entry point
  .stkPush                   — STKPushService instance

STKPushService               — STK Push API operations
  .initiatePayment(...)      — Send payment prompt to customer
  .parseCallback(from:)      — Parse callback JSON (static)

STKPushRequest               — Payment request model
STKPushResponse              — Payment response model
STKPushCallback              — Callback payload model
  .CallbackItem              — Single metadata item
  .AnyCodableValue           — Type-erased value (String, Int, or Double)

STKPushTransactionType       — .customerPayBillOnline | .customerBuyGoodsOnline
STKPushResultCode            — .success | .cancelledByUser | .transactionExpired | ...

MpesaError                   — SDK error type
MpesaConfiguration           — SDK configuration
MpesaEnvironment             — .sandbox | .production
```
