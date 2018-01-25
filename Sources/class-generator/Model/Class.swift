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

        // sort the properties by name if requested
        let alphabetize = (map.context as? MappingContext)?.alphabetizeProperties == true
        let originalProperties: [Property] = try map.value(Keys.properties.rawValue)
        properties = alphabetize ? originalProperties.sorted { $0.name.compare($1.name) == .orderedAscending } : originalProperties
    }

    // MARK: - Mappable

    func mapping(map: Map) {
        name >>> map[Keys.name.rawValue]
        properties >>> map[Keys.properties.rawValue]
    }

}
