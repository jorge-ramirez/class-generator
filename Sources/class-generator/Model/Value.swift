import Foundation
import ObjectMapper

internal class Value: ImmutableMappable {

    // MARK: - Public Properties

    /// The name of the enum value.
    /// Example: "invalidPromoCode"
    internal let name: String

    /// The raw value of the enum value.
    /// Example: "INVALID_PROMO_CODE"
    internal let rawValue: String

    // MARK: - Private Enums

    private enum Keys: String {
        case name
        case rawValue

        static let all: [Keys] = [.name, .rawValue]
    }

    // MARK: - Private Properties

    /// The original JSON used to populate the Propery object.
    private var originalJSON: [String: Any]?

    // MARK: - Initialization

    internal init(name: String, rawValue: String) {
        self.name = name
        self.rawValue = rawValue
    }

    internal required init(map: Map) throws {
        name = try map.value(Keys.name.rawValue)
        rawValue = try map.value(Keys.rawValue.rawValue)

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
        rawValue >>> map[Keys.rawValue.rawValue]
    }

}
