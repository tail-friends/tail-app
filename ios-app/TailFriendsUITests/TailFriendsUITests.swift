import XCTest

final class TailFriendsUITests: XCTestCase {
    func testLaunchShowsLoginScreen() {
        let app = XCUIApplication()
        app.launch()

        let brand = app.staticTexts["login.brand"]
        XCTAssertTrue(brand.waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["login.apple.button"].exists)

        let homeHeader = app.descendants(matching: .any)
            .matching(identifier: "home.header")
            .firstMatch
        XCTAssertFalse(homeHeader.exists)
    }

    func testHomePreviewScrollsAndKeepsBottomNavigationVisible() {
        let app = XCUIApplication()
        app.launchArguments.append("--preview-home")
        app.launch()

        let scrollView = app.scrollViews["home.scroll"]
        XCTAssertTrue(scrollView.waitForExistence(timeout: 5))

        let emptyRecords = app.descendants(matching: .any)
            .matching(identifier: "home.records.empty")
            .firstMatch
        let bottomNavigation = app.descendants(matching: .any)
            .matching(identifier: "home.bottomNavigation")
            .firstMatch
        let window = app.windows.firstMatch

        XCTAssertTrue(window.waitForExistence(timeout: 5))
        XCTAssertTrue(bottomNavigation.waitForExistence(timeout: 5))
        let initialNavigationFrame = bottomNavigation.frame
        XCTAssertTrue(
            window.frame.contains(initialNavigationFrame),
            "Bottom navigation must be visible inside the window: \(initialNavigationFrame) vs \(window.frame)"
        )
        XCTAssertTrue(emptyRecords.waitForExistence(timeout: 5))

        for _ in 0..<8 where !emptyRecords.isHittable {
            scrollView.swipeUp()
        }

        XCTAssertTrue(emptyRecords.isHittable)
        XCTAssertTrue(bottomNavigation.exists)
        let finalNavigationFrame = bottomNavigation.frame
        XCTAssertTrue(
            window.frame.contains(finalNavigationFrame),
            "Bottom navigation must stay visible after scrolling: \(finalNavigationFrame) vs \(window.frame)"
        )
        XCTAssertEqual(finalNavigationFrame.minY, initialNavigationFrame.minY, accuracy: 1)
        XCTAssertEqual(finalNavigationFrame.maxY, initialNavigationFrame.maxY, accuracy: 1)
    }
}
