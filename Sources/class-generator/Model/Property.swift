import Foundation
import ObjectMapper

internal class Property: ImmutableMappable {

    // MARK: - Public Properties

    /// The name of the property.
    /// Example: "user" or "firstName"
    let name: String

    /// The property's data type, including if it is a collection and if it's optional.
    /// Example: "String", "String?", "[String]" or "[String]?"
    let type: String

    /// An optional description of the property.
    let description: String?

    // Whether the property is a collection.
    var isCollection: Bool {
        return type.hasPrefix("[")
    }

    /// Whether the property is optional.
    var isOptional: Bool {
        return type.hasSuffix("?")
    }

    /// The raw data type of the property.
    /// Example: If the type is "[String]?" or "[String]", the rawType would be "String"
    var rawType: String {
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
    }

    // MARK: - Initialization

    init(name: String, type: String, description: String? = nil) {
        self.name = name
        self.type = type
        self.description = description
    }

    required init(map: Map) throws {
        name = try map.value(Keys.name.rawValue)
        type = try map.value(Keys.type.rawValue)
        description = try? map.value(Keys.description.rawValue)
    }

    // MARK: - Mappable

    func mapping(map: Map) {
        name >>> map[Keys.name.rawValue]
        type >>> map[Keys.type.rawValue]
        description >>> map[Keys.description.rawValue]

        isCollection >>> map[Keys.isCollection.rawValue]
        isOptional >>> map[Keys.isOptional.rawValue]
        rawType >>> map[Keys.rawType.rawValue]
    }

}
