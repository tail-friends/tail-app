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

    func testRegistrationPreviewSupportsEditingAndSelections() {
        let app = XCUIApplication()
        app.launchArguments.append("--preview-registration")
        app.launch()

        let scrollView = app.scrollViews["registration.scroll"]
        XCTAssertTrue(scrollView.waitForExistence(timeout: 5))
        XCTAssertFalse(app.buttons["registration.photo.add"].exists)
        XCTAssertEqual(
            app.staticTexts["registration.save.guidance"].label,
            "저장하면 사진으로 캐릭터를 만들 수 있어요"
        )

        let name = app.textFields["registration.name"]
        XCTAssertTrue(name.waitForExistence(timeout: 5))
        name.tap()
        let clearName = app.buttons["registration.name.clear"]
        XCTAssertTrue(clearName.waitForExistence(timeout: 3))
        clearName.tap()
        name.typeText("Sample")
        XCTAssertEqual(name.value as? String, "Sample")
        XCTAssertEqual(app.staticTexts["registration.name.count"].label, "6/30")

        let species = app.textFields["registration.species"]
        species.tap()
        let clearSpecies = app.buttons["registration.species.clear"]
        XCTAssertTrue(clearSpecies.waitForExistence(timeout: 3))
        clearSpecies.tap()
        species.typeText("Crested Gecko")
        XCTAssertEqual(species.value as? String, "Crested Gecko")

        let keyboardDone = app.buttons["registration.keyboard.done"]
        if keyboardDone.waitForExistence(timeout: 2) {
            keyboardDone.tap()
        }

        let femaleOption = app.buttons["registration.sex.female"]
        if !femaleOption.isHittable {
            scrollView.swipeUp()
        }
        XCTAssertTrue(femaleOption.waitForExistence(timeout: 3))
        femaleOption.tap()
        XCTAssertEqual(femaleOption.value as? String, "선택됨")

        let hatchDate = app.buttons["registration.hatchDate"]
        if !hatchDate.isHittable {
            scrollView.swipeUp()
        }
        hatchDate.tap()
        let datePickerDone = app.buttons["registration.hatchDate.done"]
        XCTAssertTrue(datePickerDone.waitForExistence(timeout: 3))
        datePickerDone.tap()

        let feedingInterval = app.textFields["registration.feedingInterval"]
        if !feedingInterval.isHittable {
            scrollView.swipeUp()
        }
        feedingInterval.tap()
        let clearInterval = app.buttons["registration.feedingInterval.clear"]
        XCTAssertTrue(clearInterval.waitForExistence(timeout: 3))
        clearInterval.tap()
        feedingInterval.typeText("6")
        XCTAssertEqual(feedingInterval.value as? String, "6")

        if keyboardDone.waitForExistence(timeout: 2) {
            keyboardDone.tap()
        }

        let memo = app.textViews["registration.memo"]
        if !memo.isHittable {
            scrollView.swipeUp()
        }
        XCTAssertTrue(memo.waitForExistence(timeout: 3))
        XCTAssertEqual(memo.value as? String, "온순함, 손을 좋아함")

        let memoCount = app.staticTexts["registration.memo.count"]
        XCTAssertEqual(memoCount.label, "13/300")

        let memoScreenshot = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        memoScreenshot.name = "Registration memo initial content"
        memoScreenshot.lifetime = .keepAlways
        add(memoScreenshot)

        memo.tap()
        memo.typeText("!")
        let updatedMemo = memo.value as? String ?? ""
        XCTAssertTrue(updatedMemo.contains("!"))
        XCTAssertEqual(memoCount.label, "\(updatedMemo.count)/300")

        if keyboardDone.waitForExistence(timeout: 2) {
            keyboardDone.tap()
        }

        let save = app.buttons["registration.save"]
        XCTAssertTrue(save.waitForExistence(timeout: 3))
        save.tap()
        XCTAssertTrue(app.alerts["저장 미리보기"].waitForExistence(timeout: 3))
    }

    func testFeedingRecordPreviewSupportsSelectionAndEditing() {
        let app = XCUIApplication()
        app.launchArguments.append("--preview-feeding-record")
        app.launch()

        let scrollView = app.scrollViews["feeding.scroll"]
        XCTAssertTrue(scrollView.waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["기록 추가"].exists)

        let cricket = app.buttons["feeding.food.cricket"]
        let mealworm = app.buttons["feeding.food.mealworm"]
        XCTAssertTrue(cricket.waitForExistence(timeout: 3))
        XCTAssertEqual(cricket.value as? String, "선택됨")
        mealworm.tap()
        XCTAssertEqual(mealworm.value as? String, "선택됨")
        cricket.tap()

        let quantity = app.staticTexts["feeding.quantity.value"]
        XCTAssertEqual(quantity.label, "5")
        app.buttons["feeding.quantity.decrease"].tap()
        XCTAssertEqual(quantity.label, "4")
        app.buttons["feeding.quantity.increase"].tap()
        XCTAssertEqual(quantity.label, "5")

        let notEaten = app.buttons["feeding.notEaten"]
        XCTAssertEqual(notEaten.value as? String, "끔")
        notEaten.tap()
        XCTAssertEqual(notEaten.value as? String, "켬")
        notEaten.tap()

        let memo = app.textFields["feeding.memo"]
        if !memo.isHittable {
            scrollView.swipeUp()
        }
        XCTAssertTrue(memo.waitForExistence(timeout: 3))
        XCTAssertEqual(memo.value as? String, "잘 받아먹음")
        memo.tap()
        let clearMemo = app.buttons["feeding.memo.clear"]
        XCTAssertTrue(clearMemo.waitForExistence(timeout: 3))
        clearMemo.tap()
        memo.typeText("잘 먹었어요")
        XCTAssertEqual(memo.value as? String, "잘 먹었어요")

        let keyboardDone = app.buttons["feeding.memo.done"]
        if keyboardDone.waitForExistence(timeout: 2) {
            keyboardDone.tap()
        }

        let save = app.buttons["feeding.save"]
        if !save.isHittable {
            scrollView.swipeUp()
        }
        save.tap()
        XCTAssertTrue(app.alerts["저장 미리보기"].waitForExistence(timeout: 3))
    }

    func testFeedingRecordSheetCanBeDismissedByDraggingHandle() {
        let app = XCUIApplication()
        app.launchArguments.append("--preview-feeding-record")
        app.launch()

        let sheetTitle = app.staticTexts["기록 추가"]
        XCTAssertTrue(sheetTitle.waitForExistence(timeout: 5))

        let handle = app.descendants(matching: .any)
            .matching(identifier: "feeding.sheet.handle")
            .firstMatch
        XCTAssertTrue(handle.waitForExistence(timeout: 3))

        let start = handle.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5))
        let end = app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.7))
        start.press(forDuration: 0.1, thenDragTo: end)

        XCTAssertTrue(sheetTitle.waitForNonExistence(timeout: 3))
    }

    func testFeedingRecordSheetCanBeDismissedByCloseButton() {
        let app = XCUIApplication()
        app.launchArguments.append("--preview-feeding-record")
        app.launch()

        let sheetTitle = app.staticTexts["기록 추가"]
        XCTAssertTrue(sheetTitle.waitForExistence(timeout: 5))
        app.buttons["feeding.close"].tap()

        XCTAssertTrue(sheetTitle.waitForNonExistence(timeout: 3))
    }
}
