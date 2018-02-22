import Foundation
import ObjectMapper

internal class Schema: ImmutableMappable {

    // MARK: - Public Properties

    /// The schema version used.
    /// Example: "1.0"
    internal let version: String

    /// An array of data types. Either "class" or "enum".
    internal let dataTypes: [DataType]

    // MARK: - Private Enums

    private enum Keys: String {
        case version
        case dataTypes
    }

    // MARK: - Initialization

    internal init(version: String, dataTypes: [DataType]) {
        self.version = version
        self.dataTypes = dataTypes
    }

    internal required init(map: Map) throws {
        version = try map.value(Keys.version.rawValue)
        dataTypes = try map.value(Keys.dataTypes.rawValue, using: DataTypeTransformType())
    }

    // MARK: - Mappable

    internal func mapping(map: Map) {
        version >>> map[Keys.version.rawValue]
        dataTypes >>> map[Keys.dataTypes.rawValue]
    }

}
