import Foundation
import ObjectMapper

internal class Property: ImmutableMappable {

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
        case name
        case dataType
        case description
        case isCollection
        case isOptional
        case rawDataType

        static let all: [Keys] = [.name, .dataType, .description, .isCollection, .isOptional, .rawDataType]
    }

    // MARK: - Private Properties

    /// The original JSON used to populate the Propery object.
    private var originalJSON: [String: Any]?

    // MARK: - Initialization

    internal init(name: String, dataType: String, description: String? = nil) {
        self.name = name
        self.dataType = dataType
        self.description = description
    }

    internal required init(map: Map) throws {
        name = try map.value(Keys.name.rawValue)
        dataType = try map.value(Keys.dataType.rawValue)
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
        dataType >>> map[Keys.dataType.rawValue]
        description >>> map[Keys.description.rawValue]

        isCollection >>> map[Keys.isCollection.rawValue]
        isOptional >>> map[Keys.isOptional.rawValue]
        rawDataType >>> map[Keys.rawDataType.rawValue]
    }

}
