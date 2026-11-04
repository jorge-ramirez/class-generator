import Foundation

internal class Value: Codable {

    // MARK: - Public Properties

    /// The name of the enum value.
    /// Example: "invalidPromoCode"
    internal let name: String

    /// The value of the enum value.
    /// Example: "INVALID_PROMO_CODE" or "10001"
    internal let value: String

    // MARK: - Private Enums

    private enum Keys: String {
        case name
        case value

        static let all: Set<String> = ["name", "value"]
    }

    // MARK: - Private Properties

    /// The original JSON used to populate the Value object.
    private var extraValues: [String: JSONValue]

    // MARK: - Initialization

    internal init(name: String, value: String) {
        self.name = name
        self.extraValues = [:]
        self.value = value
    }

    internal required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: AnyCodingKey.self)

        name = try container.decode(String.self, forKey: AnyCodingKey(Keys.name.rawValue))
        extraValues = try container.decodeExtras(excluding: Keys.all)
        value = try container.decode(String.self, forKey: AnyCodingKey(Keys.value.rawValue))
    }

    // MARK: - Encodable

    internal func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: AnyCodingKey.self)

        try container.encode(name, forKey: AnyCodingKey(Keys.name.rawValue))
        try container.encode(value, forKey: AnyCodingKey(Keys.value.rawValue))
        try container.encodeExtras(extraValues)
    }

}
