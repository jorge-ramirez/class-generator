import Foundation

internal enum Type {
    case bool
    case custom(String)
    case decimal
    case double
    case int
    case long
    case string

    init(stringValue: String) {
        switch stringValue {
        case "Bool":
            self = .bool
        case "Decimal":
            self = .decimal
        case "Double":
            self = .double
        case "Int":
            self = .int
        case "Long":
            self = .long
        case "String":
            self = .string
        default:
            self = .custom(stringValue)
        }
    }

    func stringValue() -> String {
        switch self {
        case .bool:
            return "Bool"
        case let .custom(typeName):
            return typeName
        case .decimal:
            return "Decimal"
        case .double:
            return "Double"
        case .int:
            return "Int"
        case .long:
            return "Long"
        case .string:
            return "String"
        }
    }
}
