function swiftNameAndTypeDeclaration(property) {
    var declaration = property.name + ": "

    if (property.isCollection) {
        declaration += "["
    }

    declaration += property.rawDataType

    if (property.isCollection) {
        declaration += "]"
    }

    if (property.isOptional) {
        declaration += "?"
    }

    return declaration
}

registerPreDefinedTypes(["Bool", "Date", "Decimal", "Double", "Float", "Int", "Long", "String"])
registerFilter("swiftNameAndTypeDeclaration", "swiftNameAndTypeDeclaration", "string")
