import XCTest

final class TailFriendsUITests: XCTestCase {
    func testLaunchShowsHomeScreen() {
        let app = XCUIApplication()
        app.launch()

        let header = app.descendants(matching: .any)
            .matching(identifier: "home.header")
            .firstMatch
        XCTAssertTrue(header.waitForExistence(timeout: 5))

        let hero = app.descendants(matching: .any)
            .matching(identifier: "home.hero")
            .firstMatch
        XCTAssertTrue(hero.exists)
        XCTAssertTrue(app.buttons["home.feeding.button"].exists)
        XCTAssertTrue(app.buttons["home.bottomNavigation.habitat"].exists)
    }
}
