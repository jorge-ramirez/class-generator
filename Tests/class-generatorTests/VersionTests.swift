import XCTest

@testable import class_generator

internal final class VersionTests: XCTestCase {

    internal func testVersionIsSemanticVersion() {
        XCTAssertNotNil(Version.current.range(of: #"^\d+\.\d+\.\d+$"#, options: .regularExpression))
    }

    internal func testCommandReportsSharedVersion() {
        XCTAssertEqual(ClassGeneratorCommand.configuration.version, Version.current)
    }

}
