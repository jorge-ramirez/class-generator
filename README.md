# class-generator

[![Build Status](https://travis-ci.org/jorge-ramirez/class-generator.svg?branch=master)](https://travis-ci.org/jorge-ramirez/class-generator)

class-generator is a macOS command line tool which generates classes based on JSON files used to describe the classes and their properties.  It was created to help reduce the manual process of creating mapper classes used in REST service calls in iOS and macOS apps.  Since it is template based, it can be used to generate classes for any programming language.

##### JSON:

The input JSON files should consist of an array of class objects:

##### Classes:

```
{
    "name": "UsersResponse", // String: The name of the class (this will also be the name of the file that is generated)
    "properties": [] // Array: Array of Property objects (see below)
}
```

##### Properties:

```
{
    "name": "Foo", // String: The name of the property (Required)
    "type": "String", // String: The data type of the property (Bool, Date, Decimal, Double, Float, Int, Long, String or user-defined) (Required)
    "isRequired": true, // Bool: Whether or not the property is required.  (True by default) 
    "isCollection": false, // Bool: Whether or not the property is a collection (an array of 'type' objects').  (False by default) 
    "description": "" // String: A short description of the property.  This can be used in the tempalte. (Null by default)
},
```

##### Example JSON (UserResponse.json):

```
[
    {
        "name": "UsersResponse",
        "properties": [
            { "name": "users", "type": "User", "isCollection": true }
        ]
    },
    {
        "name": "User",
        "properties": [
            { "name": "firstName", "type": "String" },
            { "name": "lastName", "type": "String" },
            { "name": "age", "type": "Int", "isRequired": false },
            { "name": "address", "type": "Address", "isRequired": false }
        ]
    },
    {
        "name": "Address",
        "properties": [
            { "name": "streetAddress1", "type": "String" },
            { "name": "streetAddress2", "type": "String", "isRequired": false },
            { "name": "city", "type": "String" },
            { "name": "state", "type": "String" },
            { "name": "zipcode", "type": "Int" }
        ]
    }
]
```

##### Templates:

Template parsing is done using the `Stencil` (https://github.com/kylef/Stencil) library.  Which means templates must use the `Stencil Template Language` (https://stencil.fuller.li/en/latest/).

##### Example Template (for a Swift ObjectMapper class):

```
import Foundation
import ObjectMapper

internal class {{ name }}: ImmutableMappable {

    // MARK: - Public Properties
    {% for property in properties %}
    let {{ property|swiftPropertyDeclaration }}{% endfor %}

    // MARK: - Private Enums

    fileprivate enum Keys: String { {% for property in properties %}
        case {{ property.name }}{% endfor %}
    }

    // MARK: - Initialization

    init({% for property in properties %}{{ property|swiftPropertyDeclaration }}{% if not forloop.last %},
         {% endif %}{% endfor %}) { {% for property in properties %}
        self.{{ property.name }} = {{ property.name }}{% endfor %}
    }

    required init(map: Map) throws { {% for property in properties %}{% if property.type == "Date" %}
        {{ property.name }} = try{% if not property.isRequired %}?{% endif %} map.value(Keys.{{ property.name }}.rawValue, using: ISO8601DateTransform()){% else %}
        {{ property.name }} = try{% if not property.isRequired %}?{% endif %} map.value(Keys.{{ property.name }}.rawValue){% endif %}{% endfor %}
    }

    // MARK: - Mappable

    func mapping(map: Map) { {% for property in properties %}{% if property.type == "Date" %}
        {{ property.name }} >>> (map[Keys.{{ property.name }}.rawValue], ISO8601DateTransform()){% else %}
        {{ property.name }} >>> map[Keys.{{ property.name }}.rawValue]{% endif %}{% endfor %}
    }

}
```

##### Generated Output (using the above JSON data and template):

###### UserResponse.swift

```
import Foundation
import ObjectMapper

internal class UsersResponse: ImmutableMappable {

    // MARK: - Public Properties
    
    let users: [User]

    // MARK: - Private Enums

    fileprivate enum Keys: String { 
        case users
    }

    // MARK: - Initialization

    init(users: [User]) { 
        self.users = users
    }

    required init(map: Map) throws { 
        users = try map.value(Keys.users.rawValue)
    }

    // MARK: - Mappable

    func mapping(map: Map) { 
        users >>> map[Keys.users.rawValue]
    }

}
```

###### User.swift

```
import Foundation
import ObjectMapper

internal class User: ImmutableMappable {

    // MARK: - Public Properties
    
    let address: Address?
    let age: Int?
    let firstName: String
    let lastName: String

    // MARK: - Private Enums

    fileprivate enum Keys: String { 
        case address
        case age
        case firstName
        case lastName
    }

    // MARK: - Initialization

    init(address: Address?,
         age: Int?,
         firstName: String,
         lastName: String) { 
        self.address = address
        self.age = age
        self.firstName = firstName
        self.lastName = lastName
    }

    required init(map: Map) throws { 
        address = try? map.value(Keys.address.rawValue)
        age = try? map.value(Keys.age.rawValue)
        firstName = try map.value(Keys.firstName.rawValue)
        lastName = try map.value(Keys.lastName.rawValue)
    }

    // MARK: - Mappable

    func mapping(map: Map) { 
        address >>> map[Keys.address.rawValue]
        age >>> map[Keys.age.rawValue]
        firstName >>> map[Keys.firstName.rawValue]
        lastName >>> map[Keys.lastName.rawValue]
    }

}
```

##### General Usage:

```
> class-generator help

Usage: class-generator <command> [options]

class-generator - Generate classes from JSON schemas

Commands:
  generate        Generates an output file for each class definition found in the specified schemas, using the specified template.
  help            Prints this help information
  version         Prints the current version of this app
```

##### generate

This command will generate a class file for each class represented in the JSON schemas that are loaded from the input directory.

##### Usage:

```
> class-generator generate --help

Usage: class-generator generate <schemasDirectoryPath> <templateFilePath> [options]

Options:
  --alphabetize-properties           The generated properties will be listed alphabetical order.
  --output-directory-path <value>    The output directory where all generated files will be saved to.  A temporary directory will be used if none is provided.
  -h, --help                         Show help information for this command
```

##### Example:

```
> class-generator generate \
  ~/Desktop/schemas \
  ~/Desktop/templates/swift-object-mapper.txt \
  --alphabetize-properties
```

This will load all of the class schemas located in the `schemas` input directory, and then use the `swift-object-mapper.txt` template to generate a file for each of the loaded classes.

## Binary Installation

- Download the latest release archive from the [releases](https://github.com/jorge-ramirez/class-generator/releases/latest) page.
- Unzip the file.
- Copy the `class-generator` binary to somewhere in your `PATH` (for example `/usr/local/bin`).
- Run the commands as shown in the examples above.

## Building from Source

class-generator uses the [Swift Package Manager](https://github.com/apple/swift-package-manager).  After cloning the repository, change directories into the repository's directory and run the `swift build` command.  You should see something like the following:

```
> swift build
  Fetching https://github.com/kylef/PathKit.git
  Fetching https://github.com/kylef/Stencil.git
  Fetching https://github.com/jakeheis/SwiftCLI.git
  Fetching https://github.com/Hearst-DD/ObjectMapper.git
  Fetching https://github.com/kylef/Spectre.git
  Cloning https://github.com/kylef/Stencil.git
  Resolving https://github.com/kylef/Stencil.git at 0.10.1
  Cloning https://github.com/kylef/Spectre.git
  Resolving https://github.com/kylef/Spectre.git at 0.7.2
  Cloning https://github.com/jakeheis/SwiftCLI.git
  Resolving https://github.com/jakeheis/SwiftCLI.git at 4.0.3
  Cloning https://github.com/kylef/PathKit.git
  Resolving https://github.com/kylef/PathKit.git at 0.8.0
  Cloning https://github.com/Hearst-DD/ObjectMapper.git
  Resolving https://github.com/Hearst-DD/ObjectMapper.git at 3.1.0
  Compile Swift Module 'Spectre' (8 sources)
  Compile Swift Module 'SwiftCLI' (25 sources)
  Compile Swift Module 'ObjectMapper' (23 sources)
  Compile Swift Module 'class_generator' (7 sources)
  Linking ./.build/x86_64-apple-macosx10.10/debug/class-generator
```

You can then find the binary at `.build/debug/class-generator`.

##### Attribution:

`class-generator` uses the following libraries:

- [PathKit](https://github.com/kylef/PathKit.git)
- [Stencil](https://github.com/kylef/Stencil.git)
- [SwiftCLI](https://github.com/jakeheis/SwiftCLI.git)
- [ObjectMapper](https://github.com/Hearst-DD/ObjectMapper.git)
- [HeliumLogger](https://github.com/IBM-Swift/HeliumLogger.git)
