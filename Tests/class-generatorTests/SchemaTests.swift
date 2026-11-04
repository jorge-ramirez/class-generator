import XCTest

@testable import class_generator

internal final class SchemaTests: XCTestCase {

    internal func testDecodesClassesAndEnums() throws {
        let json = """
            {
              "version": "2.1",
              "dataTypes": [
                {
                  "name": "User",
                  "properties": [
                    { "name": "id", "dataType": "Int" }
                  ]
                },
                {
                  "name": "Role",
                  "type": "enum",
                  "dataType": "String",
                  "values": [
                    { "name": "administrator", "value": "10001" }
                  ]
                }
              ]
            }
            """

        let schema = try JSONDecoder().decode(Schema.self, from: Data(json.utf8))

        XCTAssertEqual(schema.dataTypes.count, 2)
        XCTAssertTrue(schema.dataTypes[0] is Class)
        XCTAssertTrue(schema.dataTypes[1] is Enum)
    }

}
