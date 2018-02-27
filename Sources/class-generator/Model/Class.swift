import Foundation
import ObjectMapper

internal class Class: DataType {

    // MARK: - Public Properties

    /// An array of the class' properties.
    internal let properties: [Property]

    // MARK: - Private Enums

    private enum Keys: String {
        case properties

        static let all: [Keys] = [.properties]
    }

    // MARK: - Private Properties

    /// The original JSON used to populate the Propery object.
    private var originalJSON: [String: Any]?

    // MARK: - Initialization

    internal init(name: String, properties: [Property]) {
        self.properties = properties

        super.init(name: name, type: .class)
    }

    internal required init(map: Map) throws {
        properties = try Class.extractProperties(map: map)

        // save the original JSON data, minus the existing properties
        let keysToExclude = Keys.all.map { $0.rawValue }
        originalJSON = map.JSON.filter { key, _ in
            !keysToExclude.contains(key)
        }

        try super.init(map: map)
    }

    // MARK: - Mappable

    internal override func mapping(map: Map) {
        // map the original json data
        originalJSON?.forEach { key, value in
            value >>> map[key]
        }

        super.mapping(map: map)
        properties >>> map[Keys.properties.rawValue]
    }

    // MARK: - Private Methods

    private class func extractProperties(map: Map) throws -> [Property] {
        var properties: [Property] = try map.value(Keys.properties.rawValue)

        if shouldAlphabetizeProperties(map: map) {
            properties.sort { $0.name.compare($1.name, options: .caseInsensitive) == .orderedAscending }
        }

        return properties
    }

    private class func shouldAlphabetizeProperties(map: Map) -> Bool {
        guard let context = map.context as? MappingContext else {
            return false
        }

        return context.alphabetizeProperties
    }

}
