import Foundation

internal class Class: DataType {

    // MARK: - Public Properties

    /// An array of the class' properties.
    internal private(set) var properties: [Property]

    // MARK: - Private Enums

    private enum Keys: String {
        case properties

        static let all: Set<String> = ["name", "properties", "type"]
    }

    // MARK: - Private Properties

    /// The original JSON used to populate the Class object.
    private var extraValues: [String: JSONValue]

    // MARK: - Initialization

    internal init(name: String, properties: [Property]) {
        self.extraValues = [:]
        self.properties = properties

        super.init(name: name, type: .class)
    }

    internal required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: AnyCodingKey.self)

        properties = try container.decode([Property].self, forKey: AnyCodingKey(Keys.properties.rawValue))
        extraValues = try container.decodeExtras(excluding: Keys.all)

        try super.init(from: decoder)
    }

    // MARK: - Public Methods

    internal func alphabetizeProperties() {
        properties.sort { $0.name.compare($1.name, options: .caseInsensitive) == .orderedAscending }
    }

    // MARK: - Encodable

    internal override func encode(to encoder: Encoder) throws {
        try super.encode(to: encoder)

        var container = encoder.container(keyedBy: AnyCodingKey.self)

        try container.encode(properties, forKey: AnyCodingKey(Keys.properties.rawValue))
        try container.encodeExtras(extraValues)
    }

}
