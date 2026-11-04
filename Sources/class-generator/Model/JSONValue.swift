import Foundation

/// A coding key that can represent any string key found in a JSON object.
internal struct AnyCodingKey: CodingKey {

    internal let stringValue: String
    internal let intValue: Int?

    internal init(stringValue: String) {
        self.stringValue = stringValue
        self.intValue = nil
    }

    internal init(_ stringValue: String) {
        self.init(stringValue: stringValue)
    }

    internal init?(intValue: Int) {
        self.stringValue = String(intValue)
        self.intValue = intValue
    }

}

/// A type-erased JSON value used to preserve keys which are not part of a model.
internal enum JSONValue: Codable {

    case array([JSONValue])
    case bool(Bool)
    case double(Double)
    case int(Int)
    case null
    case object([String: JSONValue])
    case string(String)

    // MARK: - Codable

    internal init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()

        if container.decodeNil() {
            self = .null
        } else if let value = try? container.decode(Bool.self) {
            self = .bool(value)
        } else if let value = try? container.decode(Int.self) {
            self = .int(value)
        } else if let value = try? container.decode(Double.self) {
            self = .double(value)
        } else if let value = try? container.decode(String.self) {
            self = .string(value)
        } else if let value = try? container.decode([JSONValue].self) {
            self = .array(value)
        } else if let value = try? container.decode([String: JSONValue].self) {
            self = .object(value)
        } else {
            throw DecodingError.dataCorruptedError(in: container,
                                                   debugDescription: "Unsupported JSON value")
        }
    }

    internal func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()

        switch self {
        case .array(let value):
            try container.encode(value)
        case .bool(let value):
            try container.encode(value)
        case .double(let value):
            try container.encode(value)
        case .int(let value):
            try container.encode(value)
        case .null:
            try container.encodeNil()
        case .object(let value):
            try container.encode(value)
        case .string(let value):
            try container.encode(value)
        }
    }

}

internal extension KeyedDecodingContainer where Key == AnyCodingKey {

    /// Decodes every key which is not part of `knownKeys`.
    func decodeExtras(excluding knownKeys: Set<String>) throws -> [String: JSONValue] {
        var extras: [String: JSONValue] = [:]

        for key in allKeys where !knownKeys.contains(key.stringValue) {
            extras[key.stringValue] = try decode(JSONValue.self, forKey: key)
        }

        return extras
    }

}

internal extension KeyedEncodingContainer where Key == AnyCodingKey {

    /// Encodes every preserved JSON key which is not part of the model.
    mutating func encodeExtras(_ extras: [String: JSONValue]) throws {
        for (key, value) in extras {
            try encode(value, forKey: AnyCodingKey(key))
        }
    }

}
