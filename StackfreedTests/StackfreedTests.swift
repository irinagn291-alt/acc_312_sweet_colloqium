import XCTest
@testable import Stackfreed

final class StackfreedTests: XCTestCase {
    func test_appModuleImports() {
        XCTAssertEqual(String(describing: StackfreedApp.self), "StackfreedApp")
    }
}
