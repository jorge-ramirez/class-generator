import Foundation
import ObjectMapper

internal class Property: ImmutableMappable {

    // MARK: - Public Properties

    let name: String
    let type: Type
    let isArray: Bool
    let isRequired: Bool

    // MARK: - Private Enums

    fileprivate enum Keys: String {
        case name
        case type
        case isArray
        case isRequired
    }

    // MARK: - Initialization

    init(name: String, type: Type, isArray: Bool = false, isRequired: Bool = true) {
        self.name = name
        self.type = type
        self.isArray = isArray
        self.isRequired = isRequired
    }

    required init(map: Map) throws {
        name = try map.value(Keys.name.rawValue)

        let typeString: String = try map.value(Keys.type.rawValue)
        type = Type(stringValue: typeString)

        isArray = (try? map.value(Keys.isArray.rawValue)) ?? false
        isRequired = (try? map.value(Keys.isRequired.rawValue)) ?? true
    }

    // MARK: - Mappable

    func mapping(map: Map) {
        name >>> map[Keys.name.rawValue]

        let typeString = type.stringValue()
        typeString >>> map[Keys.type.rawValue]

        isArray >>> map[Keys.isArray.rawValue]
        isRequired >>> map[Keys.isRequired.rawValue]
    }

}
