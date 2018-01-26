import Foundation
import ObjectMapper

internal class Property: ImmutableMappable {

    // MARK: - Public Properties

    let name: String
    let type: Type
    let isCollection: Bool
    let isRequired: Bool
    let description: String?

    // MARK: - Private Enums

    fileprivate enum Keys: String {
        case name
        case type
        case isCollection
        case isRequired
        case description
    }

    // MARK: - Initialization

    init(name: String, type: Type, isCollection: Bool = false, isRequired: Bool = true, description: String? = nil) {
        self.name = name
        self.type = type
        self.isCollection = isCollection
        self.isRequired = isRequired
        self.description = description
    }

    required init(map: Map) throws {
        name = try map.value(Keys.name.rawValue)

        let typeString: String = try map.value(Keys.type.rawValue)
        type = Type(stringValue: typeString)

        isCollection = (try? map.value(Keys.isCollection.rawValue)) ?? false
        isRequired = (try? map.value(Keys.isRequired.rawValue)) ?? true
        description = try? map.value(Keys.description.rawValue)
    }

    // MARK: - Mappable

    func mapping(map: Map) {
        name >>> map[Keys.name.rawValue]

        let typeString = type.stringValue()
        typeString >>> map[Keys.type.rawValue]

        isCollection >>> map[Keys.isCollection.rawValue]
        isRequired >>> map[Keys.isRequired.rawValue]
        description >>> map[Keys.description.rawValue]
    }

}
