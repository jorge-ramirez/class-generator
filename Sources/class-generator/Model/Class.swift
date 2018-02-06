import Foundation
import ObjectMapper

internal class Class: ImmutableMappable {

    // MARK: - Public Properties

    let name: String
    let properties: [Property]

    // MARK: - Private Enums

    private enum Keys: String {
        case name
        case properties

        static let all: [Keys] = [.name, .properties]
    }

    // MARK: - Private Properties

    /// The original JSON used to populate the Propery object.
    private var originalJSON: [String: Any]?

    // MARK: - Initialization

    init(name: String, properties: [Property]) {
        self.name = name
        self.properties = properties
    }

    required init(map: Map) throws {
        name = try map.value(Keys.name.rawValue)
        properties = try Class.extractProperties(map: map)

        // save the original JSON data, minus the existing properties
        let keysToExclude = Keys.all.map { $0.rawValue }
        originalJSON = map.JSON.filter { key, _ in
            return !keysToExclude.contains(key)
        }
    }

    // MARK: - Mappable

    func mapping(map: Map) {
        // map the original json data
        originalJSON?.forEach { key, value in
            value >>> map[key]
        }

        name >>> map[Keys.name.rawValue]
        properties >>> map[Keys.properties.rawValue]
    }

    // MARK: - Private Methods

    private class func extractProperties(map: Map) throws -> [Property] {
        var properties: [Property] = try map.value(Keys.properties.rawValue)

        if shouldAlphabetizeProperties(map: map) {
            properties.sort { $0.name.compare($1.name) == .orderedAscending }
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
