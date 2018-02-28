import Foundation
import ObjectMapper

internal class Enum: DataType {

    // MARK: - Public Properties

    /// The enum values' data type.
    /// Example: "String" or "Int"
    internal var dataType: String

    /// An array of the enum's allowed values.
    internal let values: [Value]

    // MARK: - Private Enums

    private enum Keys: String {
        case dataType
        case values

        static let all: [Keys] = [.dataType, .values]
    }

    // MARK: - Private Properties

    /// The original JSON used to populate the Propery object.
    private var originalJSON: [String: Any]?

    // MARK: - Initialization

    internal init(name: String, dataType: String, values: [Value]) {
        self.dataType = dataType
        self.values = values

        super.init(name: name, type: .enum)
    }

    internal required init(map: Map) throws {
        dataType = try map.value(Keys.dataType.rawValue)
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

        dataType >>> map[Keys.dataType.rawValue]
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
