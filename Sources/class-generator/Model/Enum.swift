import Foundation

internal class Enum: DataType {

    // MARK: - Public Properties

    /// The enum values' data type.
    /// Example: "String" or "Int"
    internal var dataType: String

    /// An array of the enum's allowed values.
    internal private(set) var values: [Value]

    // MARK: - Private Enums

    private enum Keys: String {
        case dataType
        case values

        static let all: Set<String> = ["dataType", "name", "type", "values"]
    }

    // MARK: - Private Properties

    /// The original JSON used to populate the Enum object.
    private var extraValues: [String: JSONValue]

    // MARK: - Initialization

    internal init(name: String, dataType: String, values: [Value]) {
        self.dataType = dataType
        self.extraValues = [:]
        self.values = values

        super.init(name: name, type: .enum)
    }

    internal required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: AnyCodingKey.self)

        dataType = try container.decode(String.self, forKey: AnyCodingKey(Keys.dataType.rawValue))
        values = try container.decode([Value].self, forKey: AnyCodingKey(Keys.values.rawValue))
        extraValues = try container.decodeExtras(excluding: Keys.all)

        try super.init(from: decoder)
    }

    // MARK: - Public Methods

    internal func alphabetizeValues() {
        values.sort { $0.name.compare($1.name, options: .caseInsensitive) == .orderedAscending }
    }

    // MARK: - Encodable

    internal override func encode(to encoder: Encoder) throws {
        try super.encode(to: encoder)

        var container = encoder.container(keyedBy: AnyCodingKey.self)

        try container.encode(dataType, forKey: AnyCodingKey(Keys.dataType.rawValue))
        try container.encode(values, forKey: AnyCodingKey(Keys.values.rawValue))
        try container.encodeExtras(extraValues)
    }

}
