import Foundation
import ObjectMapper

internal class DataTypeTransformType: TransformType {

    public typealias Object = [DataType]
    public typealias JSON = [[String: Any]]

    internal func transformToJSON(_ value: [DataType]?) -> [[String: Any]]? {
        // convert the DataType objects into JSON

        return value?.map { $0.toJSON() }
    }

    internal func transformFromJSON(_ value: Any?) -> [DataType]? {
        // convert the JSON into DataType objects

        return (value as? [[String: Any]])?.flatMap {
            let typeString = $0["type"] as? String ?? Type.class.rawValue
            guard let type = Type(rawValue: typeString) else {
                return nil
            }

            switch type {
            case .class:
                return Class(JSON: $0)
            case .enum:
                return Enum(JSON: $0)
            }
        }
    }
}
