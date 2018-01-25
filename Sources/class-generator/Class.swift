import Foundation

internal struct Class {

    let name: String
    let properties: [Property]

    init(name: String, properties: [Property]) {
        self.name = name
        self.properties = properties
    }

}
