import Foundation
import ObjectMapper

internal class Class: ImmutableMappable {

    // MARK: - Public Properties

    let name: String
    let properties: [Property]

    // MARK: - Private Enums

    fileprivate enum Keys: String {
        case name
        case properties
    }

    // MARK: - Initialization

    init(name: String, properties: [Property]) {
        self.name = name
        self.properties = properties
    }

    required init(map: Map) throws {
        name = try map.value(Keys.name.rawValue)
        properties = try map.value(Keys.properties.rawValue)
    }

    // MARK: - Mappable

    func mapping(map: Map) {
        name >>> map[Keys.name.rawValue]
        properties >>> map[Keys.properties.rawValue]
    }

}
