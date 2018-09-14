# class-generator

[![Build Status](https://travis-ci.org/jorge-ramirez/class-generator.svg?branch=master)](https://travis-ci.org/jorge-ramirez/class-generator)

`class-generator` is a macOS command line tool which generates classes based on JSON files used to describe the classes and their properties.  It was created to help reduce the manual process of creating mapper classes used in REST service calls in iOS and macOS apps.  Since it is template based, it can be used to generate classes for any language.

It takes as input, schema files written in `JSON`.  It then uses a specified template, written in `Stencil Template Language`, to generate a class file for each of the classes defined in the input schemas.  It can also load specified plugin files, written in `JavaScript`, to do additional work.

## Schemas

The JSON schema files should consist of an array of class objects at its root.  The class objects and its subtypes are defined below:

### Class DataType

 - `name` [String] The class' name.
 - `type` [String] The type of data type, (`class` or `enum`).  Defaults to `class`.
 - `properties` [array of Property objects] The class' properties.

### Property Object

 - `name` [String] The property's name.
 - `dataType` [String] The property's data type.
 - `description` [String, optional] A description of the property.

### Enum DataType

 - `name` [String] The enum's name.
 - `type` [String] The data type's type, (`class` or `enum`).  Defaults to `class`.
 - `dataType` [String] The enum values' data type.
 - `values` [array of Value objects] The enum's possible values.

### Value Object

 - `name` [String] The enum's display name.
 - `value` [String] The enum's JSON value.

#### Types

Aside from the raw data type, the type definition in a `Property` object can also specify whether the property is a collection and whether it's optional or required.

#### Collections

To specify a collection, surround the type name with square brackets. For example, an array of Strings would be specified as `[String]`.

#### Optionals

To specify an optional, add a question mark at the end of the type definition.  For example, an optional String would be specified as `String?`.

#### Example

```JSON
{
    "version": "2.1",
    "dataTypes": [
        {
            "name": "UsersResponse",
            "type": "class",
            "properties": [
                { "name": "users", "dataType": "[User]" }
            ]
        },
        {
            "name": "User",
            "properties": [
                { "name": "firstName", "dataType": "String" },
                { "name": "lastName", "dataType": "String" },
                { "name": "age", "dataType": "Int?" },
                { "name": "address", "dataType": "Address?" },
                { "name": "role", "dataType": "Role" }
            ]
        },
        {
            "name": "Address",
            "properties": [
                { "name": "streetAddress1", "dataType": "String" },
                { "name": "streetAddress2", "dataType": "String?" },
                { "name": "city", "dataType": "String" },
                { "name": "state", "dataType": "String" },
                { "name": "zipcode", "dataType": "Int" }
            ]
        },
        {
            "name": "Role",
            "type": "enum",
            "dataType": "String",
            "values": [
                { "name": "administrator", "value": "10001" },
                { "name": "moderator", "value": "10002" },
                { "name": "user", "value": "10003" }
            ]
        }
    ]
}
```

## Templates

Template parsing is done using the [`Stencil`](https://github.com/kylef/Stencil) library.  Which means templates must be written in the [`Stencil Template Language`](https://stencil.fuller.li/en/latest/).

When writing a template, the template's context represents the current class being generated.  The properties available to the template are defined below:

### Class Object

The default properties in the Class Object (see above)

### Property Object

The default properties in the Property Object (see above), plus the following:

 - `isCollection` [Bool] Whether or not the property represents a collection (for example an array).
 - `isOptional` [Bool] Whether or not the property represents an optional value.
 - `rawDataType` [String] The property's raw data type (the same value as `type`, except without the collection and optionality modifiers). 

#### Example

```Swift
//
//  {{ name }}.swift
//  Autogenerated by class-generator
//

// swiftlint:disable superfluous_disable_command
// swiftlint:disable type_name

import Foundation
import ObjectMapper

{% if type == "class" %}internal class {{ name }}: ImmutableMappable {

    // MARK: - Public Properties
    {% for property in properties %}
    let {{ property|swiftNameAndTypeDeclaration }}{% endfor %}

    // MARK: - Private Enums

    fileprivate enum Keys: String { {% for property in properties %}
        case {{ property.name }}{% endfor %}
    }

    // MARK: - Initialization

    init({% for property in properties %}{{ property|swiftNameAndTypeDeclaration }}{% if not forloop.last %},
         {% endif %}{% endfor %}) { {% for property in properties %}
        self.{{ property.name }} = {{ property.name }}{% endfor %}
    }

    required init(map: Map) throws { {% for property in properties %}{% if property.rawDataType == "Date" %}
        {{ property.name }} = try{% if property.isOptional %}?{% endif %} map.value(Keys.{{ property.name }}.rawValue, using: ISO8601DateTransform()){% else %}
        {{ property.name }} = try{% if property.isOptional %}?{% endif %} map.value(Keys.{{ property.name }}.rawValue){% endif %}{% endfor %}
    }

    // MARK: - Mappable

    func mapping(map: Map) { {% for property in properties %}{% if property.rawDataType == "Date" %}
        {{ property.name }} >>> (map[Keys.{{ property.name }}.rawValue], ISO8601DateTransform()){% else %}
        {{ property.name }} >>> map[Keys.{{ property.name }}.rawValue]{% endif %}{% endfor %}
    }

}{% elif type == "enum" %}internal enum {{ name }}: {{ dataType }}: { {% for value in values %}
    case {{ value.name }} = "{{ value.value }}"{% endfor %}
}{% endif %}
```

## Plugins

`class-generator` supports plugins written in `JavaScript`.  Plugins can currently do the following:

 - Log a message
 - Register pre-defined type.
 - Register custom template filters.
 - Register custom template tags.

### Logging

A plugin can log messages to the `class-generator` log, which can help while debugging the plugin.  Logging is done via the exposed `classGenLog` function.

#### Example

```JavaScript
classGenLog("Log a message that should appear in the class-generator log")
```

### Pre-Defined Types

Pre-defined types are types which will not be represented in the input schema while generating classes.  This can be primitive types or other custom types which will not be autogenerated, but will be referenced in the input schemas.  `class-generator` needs to know about these, in order to avoid throwing an undefined class exception while validating the input schemas.

The pre-defined types can be set in a plugin by calling the exposed `registerPreDefinedTypes` function.

#### Example

```JavaScript
registerPreDefinedTypes(["Bool", "Date", "Decimal", "Double", "Float", "Int", "Long", "String"])
```

### Custom Filters

Custom `Stencil` template filters can be registered using the exposed `registerFilter` function.  For example, the `swiftNameAndTypeDeclaration` filter is used in the example template above.  The plugin is shown below: 

#### Example

```JavaScript
function swiftNameAndTypeDeclaration(property) {
    var declaration = property.name + ": "

    if (property.isCollection) {
        declaration += "["
    }

    declaration += property.rawType

    if (property.isCollection) {
        declaration += "]"
    }

    if (property.isOptional) {
        declaration += "?"
    }

    return declaration
}

registerFilter("swiftNameAndTypeDeclaration", "swiftNameAndTypeDeclaration", "string")
```

### Custom Tags

Custom `Stencil` tags can be registered using the exposed `registerTag` function.

#### Example

```JavaScript
function myTag(context) {
    return Date.now()
}

registerTag("myTag", "myTag")
```

## General Usage:

```
> class-generator help

Usage: class-generator <command> [options]

class-generator - Generate classes from JSON schemas

Commands:
  generate        Generates an output file for each class definition found in the specified schemas, using the specified template.
  help            Prints this help information
  version         Prints the current version of this app
```

## generate command

This command will generate a class file for each class represented in the JSON schemas that are loaded from the input directory.

#### Usage

```
> class-generator generate --help

Usage: class-generator generate <schemasDirectoryPath> <templateFilePath> [options]

Options:
  --alphabetize-properties            The generated properties will be listed alphabetical order.
  --output-directory-path <value>     The output directory where all generated files will be saved to.  A temporary directory will be used if none is provided.
  --plugins-directory-path <value>    A directory containing plugins which will be loaded at runtime.
  -h, --help                          Show help information for this command
```

#### Example

```
> class-generator generate \
  ~/Desktop/class-gen/schemas \
  ~/Desktop/class-gen/templates/object-mapper.swift \
  --plugins-directory-path ~/Desktop/class-gen/plugins \
  --alphabetize-properties
```

## Binary Installation

- Download the latest release archive from the [releases](https://github.com/jorge-ramirez/class-generator/releases/latest) page.
- Unzip the file.
- Copy the `class-generator` binary to somewhere in your `PATH` (for example `/usr/local/bin`).
- Run the commands as shown in the examples above.

## Building from Source

class-generator uses the [Swift Package Manager](https://github.com/apple/swift-package-manager).  After cloning the repository, change directories into the repository's directory and run the `swift build` command.  You should see something like the following:

```bash
> swift build
Fetching https://github.com/kylef/PathKit.git
Fetching https://github.com/kylef/Stencil.git
Fetching https://github.com/jakeheis/SwiftCLI.git
Fetching https://github.com/Hearst-DD/ObjectMapper.git
Fetching https://github.com/IBM-Swift/HeliumLogger.git
Fetching https://github.com/kylef/Spectre.git
Fetching https://github.com/IBM-Swift/LoggerAPI.git
...
Compile Swift Module 'Spectre' (8 sources)
Compile Swift Module 'LoggerAPI' (1 sources)
Compile Swift Module 'SwiftCLI' (25 sources)
Compile Swift Module 'ObjectMapper' (23 sources)
Compile Swift Module 'HeliumLogger' (2 sources)
Compile Swift Module 'class_generator' (6 sources)
Linking ./.build/x86_64-apple-macosx10.10/debug/class-generator
```

You can then find the binary at `.build/debug/class-generator`.

## Attribution:

`class-generator` uses the following libraries:

- [PathKit](https://github.com/kylef/PathKit)
- [Stencil](https://github.com/kylef/Stencil)
- [SwiftCLI](https://github.com/jakeheis/SwiftCLI)
- [ObjectMapper](https://github.com/Hearst-DD/ObjectMapper)
- [HeliumLogger](https://github.com/IBM-Swift/HeliumLogger)

