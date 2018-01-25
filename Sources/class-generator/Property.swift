import Foundation

internal struct Property {

    let name: String
    let dataType: DataType
    let isList: Bool
    let isRequired: Bool

    init(name: String, dataType: DataType, isList: Bool = false, isRequired: Bool = true) {
        self.name = name
        self.dataType = dataType
        self.isList = isList
        self.isRequired = isRequired
    }

}
