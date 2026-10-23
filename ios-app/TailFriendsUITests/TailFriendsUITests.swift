import XCTest

final class TailFriendsUITests: XCTestCase {
    func testLaunchShowsPlaceholder() {
        let app = XCUIApplication()
        app.launch()

        XCTAssertTrue(app.staticTexts["placeholder.title"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["placeholder.message"].exists)
    }
}
