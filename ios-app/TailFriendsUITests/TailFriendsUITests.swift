import XCTest

final class TailFriendsUITests: XCTestCase {
    func testLaunchShowsLoginScreen() {
        let app = XCUIApplication()
        app.launch()

        XCTAssertTrue(app.staticTexts["login.brand"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["login.tagline"].exists)
        XCTAssertTrue(app.buttons["login.apple.button"].exists)
        XCTAssertTrue(app.buttons["login.kakao.button"].exists)
        XCTAssertTrue(app.buttons["login.google.button"].exists)

        let scrollView = app.scrollViews["login.scroll"]
        XCTAssertTrue(scrollView.waitForExistence(timeout: 5))
        let terms = app.staticTexts["login.terms"]
        for _ in 0..<3 where !terms.isHittable {
            scrollView.swipeUp()
        }

        XCTAssertTrue(app.buttons["login.google.button"].isHittable)
        XCTAssertTrue(terms.isHittable)
    }
}
