import XCTest
@testable import KeyFinder

final class KeyNotationConverterTests: XCTestCase {
    func testCamelotConversions() {
        XCTAssertEqual(KeyNotationConverter.openFromCamelot("8A"), "8m")
        XCTAssertEqual(KeyNotationConverter.openFromCamelot("9B"), "9d")
        XCTAssertEqual(KeyNotationConverter.traditionalFromCamelot("8A"), "Am")
        XCTAssertEqual(KeyNotationConverter.traditionalFromCamelot("10B"), "D")
    }
}
