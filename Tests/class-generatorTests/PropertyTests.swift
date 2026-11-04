import XCTest

@testable import class_generator

internal final class PropertyTests: XCTestCase {

    internal func testParsesOptionalCollectionType() {
        let property = Property(name: "values", dataType: "[String]?")

        XCTAssertTrue(property.isCollection)
        XCTAssertTrue(property.isOptional)
        XCTAssertEqual(property.rawDataType, "String")
    }

    internal func testParsesNonOptionalCollectionType() {
        let property = Property(name: "values", dataType: "[Int]")

        XCTAssertTrue(property.isCollection)
        XCTAssertFalse(property.isOptional)
        XCTAssertEqual(property.rawDataType, "Int")
    }

}
