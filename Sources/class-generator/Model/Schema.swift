import Foundation

internal class Schema: Codable {

    // MARK: - Public Properties

    /// The schema version used.
    /// Example: "1.0"
    internal let version: String

    /// An array of data types. Either "class" or "enum".
    internal let dataTypes: [DataType]

    // MARK: - Private Enums

    private enum Keys: String {
        case dataTypes
        case version
    }

    // MARK: - Initialization

    internal init(version: String, dataTypes: [DataType]) {
        self.dataTypes = dataTypes
        self.version = version
    }

    internal required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: AnyCodingKey.self)

        let wrappedDataTypes = try container.decode(
            [FailableDecodable<DataTypeWrapper>].self,
            forKey: AnyCodingKey(Keys.dataTypes.rawValue))
        dataTypes = wrappedDataTypes.compactMap { $0.value?.dataType }
        version = try container.decode(String.self, forKey: AnyCodingKey(Keys.version.rawValue))
    }

    // MARK: - Encodable

    internal func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: AnyCodingKey.self)

        try container.encode(dataTypes, forKey: AnyCodingKey(Keys.dataTypes.rawValue))
        try container.encode(version, forKey: AnyCodingKey(Keys.version.rawValue))
    }

}

/// Decodes a data type into the appropriate subclass based on its "type" value.
private struct DataTypeWrapper: Decodable {

    internal let dataType: DataType

    internal init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: AnyCodingKey.self)
        let typeKey = AnyCodingKey("type")
        let typeString = (try? container.decode(String.self, forKey: typeKey)) ?? Type.class.rawValue

        guard let type = Type(rawValue: typeString) else {
            throw DecodingError.dataCorruptedError(
                forKey: typeKey,
                in: container,
                debugDescription: "Unknown data type: \(typeString)")
        }

        switch type {
        case .class:
            dataType = try Class(from: decoder)
        case .enum:
            dataType = try Enum(from: decoder)
        }
    }

}

/// Wraps a decodable value so that a failure can be skipped instead of failing the entire array.
private struct FailableDecodable<Value: Decodable>: Decodable {

    internal let value: Value?

    internal init(from decoder: Decoder) throws {
        value = try? Value(from: decoder)
    }

}
