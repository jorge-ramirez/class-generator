import Foundation
import ObjectMapper

internal class DataType: ImmutableMappable {

    // MARK: - Public Properties

    /// The name of the data type.
    /// Example: "User" or "UserResponse"
    internal let name: String

    /// The type of data type.
    /// Defaults to "class"
    internal let type: Type

    // MARK: - Private Enums

    private enum Keys: String {
        case name
        case type
    }

    // MARK: - Initialization

    internal init(name: String, type: Type) {
        self.name = name
        self.type = type
    }

    internal required init(map: Map) throws {
        name = try map.value(Keys.name.rawValue)
        type = (try? map.value(Keys.type.rawValue)) ?? Type.class
    }

    // MARK: - Mappable

    internal func mapping(map: Map) {
        name >>> map[Keys.name.rawValue]
        type >>> map[Keys.type.rawValue]
    }

}
