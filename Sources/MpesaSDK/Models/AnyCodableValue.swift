//
//  AnyCodableValue.swift
//  MpesaSDK
//
//  Created by Muktar Aisak on 12/2/2026.
//

/// A type-erased Codable value that can hold String, Int, or Double.
/// Used in callback/result metadata where values have mixed types.
public enum AnyCodableValue: Decodable, Equatable, Sendable {
    case string(String)
    case int(Int)
    case double(Double)

    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let intVal = try? container.decode(Int.self) {
            self = .int(intVal)
        } else if let doubleVal = try? container.decode(Double.self) {
            self = .double(doubleVal)
        } else if let stringVal = try? container.decode(String.self) {
            self = .string(stringVal)
        } else {
            throw DecodingError.typeMismatch(
                AnyCodableValue.self,
                DecodingError.Context(
                    codingPath: decoder.codingPath,
                    debugDescription: "Value is not String, Int, or Double"
                )
            )
        }
    }

    /// The value as a String, if applicable.
    public var stringValue: String? {
        if case .string(let val) = self { return val }
        return nil
    }

    /// The value as an Int, if applicable.
    public var intValue: Int? {
        if case .int(let val) = self { return val }
        return nil
    }

    /// The value as a Double, if applicable.
    public var doubleValue: Double? {
        switch self {
        case .double(let val):
            return val
        case .int(let val):
            return Double(val)
        default:
            return nil
        }
    }
}

/// A key-value parameter from M-Pesa result callbacks.
/// Uses `Key`/`Value` coding keys (as opposed to `Name`/`Value` in STK Push callbacks).
public struct ResultParameter: Decodable, Sendable {
    /// The parameter key.
    public let key: String

    /// The parameter value (can be String, Int, or Double). Optional because some items lack a value.
    public let value: AnyCodableValue?

    enum CodingKeys: String, CodingKey {
        case key = "Key"
        case value = "Value"
    }
}
