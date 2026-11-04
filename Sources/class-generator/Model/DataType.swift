import Foundation

internal class DataType: Codable {

    // MARK: - Public Properties

    /// The name of the data type.
    /// Example: "User" or "UserResponse"
    internal let name: String

    /// The type of data type.
    /// Defaults to "class"
    internal let type: Type

    // MARK: - Initialization

    internal init(name: String, type: Type) {
        self.name = name
        self.type = type
    }

    internal required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: AnyCodingKey.self)

        name = try container.decode(String.self, forKey: AnyCodingKey("name"))
        type = (try? container.decode(Type.self, forKey: AnyCodingKey("type"))) ?? .class
    }

    // MARK: - Encodable

    internal func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: AnyCodingKey.self)

        try container.encode(name, forKey: AnyCodingKey("name"))
        try container.encode(type, forKey: AnyCodingKey("type"))
    }

}
