import Foundation

internal class Property: Codable {

    // MARK: - Public Properties

    /// The name of the property.
    /// Example: "user" or "firstName"
    internal let name: String

    /// The property's data type, including if it is a collection and if it's optional.
    /// Example: "String", "String?", "[String]" or "[String]?"
    internal let dataType: String

    /// An optional description of the property.
    internal let description: String?

    // Whether the property is a collection.
    internal var isCollection: Bool {
        return dataType.hasPrefix("[")
    }

    /// Whether the property is optional.
    internal var isOptional: Bool {
        return dataType.hasSuffix("?")
    }

    /// The raw data type of the property.
    /// Example: If the type is "[String]?" or "[String]", the rawDataType would be "String"
    internal var rawDataType: String {
        var startIndex = dataType.startIndex
        var endIndex = dataType.endIndex

        if isCollection {
            // acount for the square brackets at the start and end of the type declaration
            startIndex = dataType.index(after: startIndex)
            endIndex = dataType.index(before: endIndex)
        }

        if isOptional {
            // acount for the question mark at the end of the type declaration
            endIndex = dataType.index(endIndex, offsetBy: -1)
        }

        return String(dataType[startIndex..<endIndex])
    }

    // MARK: - Private Enums

    private enum Keys: String {
        case dataType
        case description
        case isCollection
        case isOptional
        case name
        case rawDataType

        static let all: Set<String> = [
            "dataType",
            "description",
            "isCollection",
            "isOptional",
            "name",
            "rawDataType"
        ]
    }

    // MARK: - Private Properties

    /// The original JSON used to populate the Property object.
    private var extraValues: [String: JSONValue]

    // MARK: - Initialization

    internal init(name: String, dataType: String, description: String? = nil) {
        self.dataType = dataType
        self.description = description
        self.name = name
        self.extraValues = [:]
    }

    internal required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: AnyCodingKey.self)

        dataType = try container.decode(String.self, forKey: AnyCodingKey(Keys.dataType.rawValue))
        description = try container.decodeIfPresent(String.self, forKey: AnyCodingKey(Keys.description.rawValue))
        name = try container.decode(String.self, forKey: AnyCodingKey(Keys.name.rawValue))
        extraValues = try container.decodeExtras(excluding: Keys.all)
    }

    // MARK: - Encodable

    internal func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: AnyCodingKey.self)

        try container.encode(dataType, forKey: AnyCodingKey(Keys.dataType.rawValue))
        try container.encodeIfPresent(description, forKey: AnyCodingKey(Keys.description.rawValue))
        try container.encode(isCollection, forKey: AnyCodingKey(Keys.isCollection.rawValue))
        try container.encode(isOptional, forKey: AnyCodingKey(Keys.isOptional.rawValue))
        try container.encode(name, forKey: AnyCodingKey(Keys.name.rawValue))
        try container.encode(rawDataType, forKey: AnyCodingKey(Keys.rawDataType.rawValue))
        try container.encodeExtras(extraValues)
    }

}
