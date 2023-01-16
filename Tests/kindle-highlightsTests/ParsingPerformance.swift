import Foundation
@testable import kindle_highlights
import XCTest

final class ParsingPerformance: XCTestCase {
    func test_performance() throws {
        let fileURL = try XCTUnwrap(Bundle.module.url(forResource: "example", withExtension: "txt", subdirectory: "TestData"))
        let raw = try String(contentsOf: fileURL)
        let parser = MyClippingsParser()
        measure {
            let parsed = try? parser.parse(raw)
            XCTAssertEqual(parsed?.count, 45)
        }
    }
}
