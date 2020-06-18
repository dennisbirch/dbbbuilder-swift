import XCTest
@testable import DBBBuilder

final class DBBBuilderPackageTests: XCTestCase {
    static var allTests = [
        ("testCreateTableStrings", DBBDatabaseSetupTests.testCreateTableStrings),
        ("testAlterTable", DBBDatabaseSetupTests.testAlterTable),
    ]
}
