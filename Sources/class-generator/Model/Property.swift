import Foundation
import ObjectMapper

internal class Property: ImmutableMappable {

    // MARK: - Public Properties

    /// The name of the property.
    /// Example: "user" or "firstName"
    internal let name: String

    /// The property's data type, including if it is a collection and if it's optional.
    /// Example: "String", "String?", "[String]" or "[String]?"
    internal let type: String

    /// An optional description of the property.
    internal let description: String?

    // Whether the property is a collection.
    internal var isCollection: Bool {
        return type.hasPrefix("[")
    }

    /// Whether the property is optional.
    internal var isOptional: Bool {
        return type.hasSuffix("?")
    }

    /// The raw data type of the property.
    /// Example: If the type is "[String]?" or "[String]", the rawType would be "String"
    internal var rawType: String {
        var startIndex = type.startIndex
        var endIndex = type.endIndex

        if isCollection {
            // acount for the square brackets at the start and end of the type declaration
            startIndex = type.index(after: startIndex)
            endIndex = type.index(before: endIndex)
        }

        if isOptional {
            // acount for the question mark at the end of the type declaration
            endIndex = type.index(endIndex, offsetBy: -1)
        }

        return String(type[startIndex..<endIndex])
    }

    // MARK: - Private Enums

    private enum Keys: String {
        case name
        case type
        case description
        case isCollection
        case isOptional
        case rawType

        static let all: [Keys] = [.name, .type, .description, .isCollection, .isOptional, .rawType]
    }

    // MARK: - Private Properties

    /// The original JSON used to populate the Propery object.
    private var originalJSON: [String: Any]?

    // MARK: - Initialization

    internal init(name: String, type: String, description: String? = nil) {
        self.name = name
        self.type = type
        self.description = description
    }

    internal required init(map: Map) throws {
        name = try map.value(Keys.name.rawValue)
        type = try map.value(Keys.type.rawValue)
        description = try? map.value(Keys.description.rawValue)

        // save the original JSON data, minus the existing properties
        let keysToExclude = Keys.all.map { $0.rawValue }
        originalJSON = map.JSON.filter { key, _ in
            !keysToExclude.contains(key)
        }
    }

    // MARK: - Mappable

    internal func mapping(map: Map) {
        // map the original json data
        originalJSON?.forEach { key, value in
            value >>> map[key]
        }

        name >>> map[Keys.name.rawValue]
        type >>> map[Keys.type.rawValue]
        description >>> map[Keys.description.rawValue]

        isCollection >>> map[Keys.isCollection.rawValue]
        isOptional >>> map[Keys.isOptional.rawValue]
        rawType >>> map[Keys.rawType.rawValue]
    }

}
