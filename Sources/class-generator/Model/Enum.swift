import Foundation
import ObjectMapper

internal class Enum: DataType {

    // MARK: - Public Properties

    /// The raw data type of the enum.
    /// Example: "String" or "Int"
    internal var rawType: String

    /// An array of the enum's allowed values.
    internal let values: [Value]

    // MARK: - Private Enums

    private enum Keys: String {
        case rawType
        case values

        static let all: [Keys] = [.rawType, .values]
    }

    // MARK: - Private Properties

    /// The original JSON used to populate the Propery object.
    private var originalJSON: [String: Any]?

    // MARK: - Initialization

    internal init(name: String, rawType: String, values: [Value]) {
        self.rawType = rawType
        self.values = values

        super.init(name: name, type: .enum)
    }

    internal required init(map: Map) throws {
        rawType = try map.value(Keys.rawType.rawValue)
        values = try Enum.extractValues(map: map)

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

        rawType >>> map[Keys.rawType.rawValue]
        values >>> map[Keys.values.rawValue]
    }

    // MARK: - Private Methods

    private class func extractValues(map: Map) throws -> [Value] {
        var values: [Value] = try map.value(Keys.values.rawValue)

        if shouldAlphabetizeValues(map: map) {
            values.sort { $0.name.compare($1.name, options: .caseInsensitive) == .orderedAscending }
        }

        return values
    }

    private class func shouldAlphabetizeValues(map: Map) -> Bool {
        guard let context = map.context as? MappingContext else {
            return false
        }

        return context.alphabetizeEnumValues
    }

}
