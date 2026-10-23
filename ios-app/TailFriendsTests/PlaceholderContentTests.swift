import XCTest
@testable import TailFriends

final class PlaceholderContentTests: XCTestCase {
    func testPlaceholderHasTitleAndMessage() {
        XCTAssertEqual(PlaceholderContent.title, "Tail Friends")
        XCTAssertEqual(PlaceholderContent.message, "The iOS app shell is ready.")
    }
}
