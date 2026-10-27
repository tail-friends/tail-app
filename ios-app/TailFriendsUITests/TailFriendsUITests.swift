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
        let foodChips = [
            cricket,
            mealworm,
            app.buttons["feeding.food.dubia"],
            app.buttons["feeding.food.superworm"]
        ]
        for chip in foodChips {
            XCTAssertTrue(chip.waitForExistence(timeout: 3))
            XCTAssertGreaterThanOrEqual(chip.frame.width, 44, "\(chip.identifier) width")
            XCTAssertGreaterThanOrEqual(chip.frame.height, 44, "\(chip.identifier) height")
        }
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
        XCTAssertTrue(app.buttons["feeding.memo.done"].waitForExistence(timeout: 5))
        let keyboard = app.keyboards.firstMatch
        XCTAssertTrue(keyboard.waitForExistence(timeout: 5))
        let clearMemo = app.buttons["feeding.memo.clear"]
        XCTAssertTrue(clearMemo.waitForExistence(timeout: 3))
        let clearMemoIsHittable = XCTNSPredicateExpectation(
            predicate: NSPredicate(format: "hittable == true"),
            object: clearMemo
        )
        XCTAssertEqual(XCTWaiter.wait(for: [clearMemoIsHittable], timeout: 5), .completed)
        XCTAssertLessThan(clearMemo.frame.maxY, keyboard.frame.minY, "Memo clear control must sit above the keyboard")
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

    func testFeedingRecordUnavailableTypesStayOnFeedingAndShowNotice() {
        let app = XCUIApplication()
        app.launchArguments.append("--preview-feeding-record")
        app.launch()

        let feeding = app.buttons["feeding.type.feeding"]
        let molting = app.buttons["feeding.type.molting"]
        let weight = app.buttons["feeding.type.weight"]
        XCTAssertTrue(feeding.waitForExistence(timeout: 5))
        XCTAssertEqual(feeding.value as? String, "선택됨")

        molting.tap()
        let notice = app.alerts["준비 중"]
        XCTAssertTrue(notice.waitForExistence(timeout: 3))
        XCTAssertTrue(notice.staticTexts["탈피 기록은 준비 중이에요."].exists)
        XCTAssertEqual(feeding.value as? String, "선택됨")
        XCTAssertEqual(molting.value as? String, "선택 안 됨")
        notice.buttons["확인"].tap()

        weight.tap()
        XCTAssertTrue(notice.waitForExistence(timeout: 3))
        XCTAssertTrue(notice.staticTexts["체중 기록은 준비 중이에요."].exists)
        XCTAssertEqual(feeding.value as? String, "선택됨")
        XCTAssertEqual(weight.value as? String, "선택 안 됨")
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

    func testFeedingRecordMemoWrapsAcrossMultipleLines() {
        let app = XCUIApplication()
        app.launchArguments.append("--preview-feeding-record")
        app.launch()

        let scrollView = app.scrollViews["feeding.scroll"]
        XCTAssertTrue(scrollView.waitForExistence(timeout: 5))

        let memo = app.textFields["feeding.memo"]
        if !memo.isHittable {
            scrollView.swipeUp()
        }
        XCTAssertTrue(memo.waitForExistence(timeout: 3))
        let initialHeight = memo.frame.height
        let sheetHandle = app.descendants(matching: .any)
            .matching(identifier: "feeding.sheet.handle")
            .firstMatch
        let sheetTitle = app.staticTexts["기록 추가"]
        let closeButton = app.buttons["feeding.close"]
        let saveButton = app.buttons["feeding.save"]
        XCTAssertTrue(sheetHandle.exists)
        XCTAssertTrue(closeButton.exists)
        XCTAssertTrue(saveButton.exists)
        let initialHandleY = sheetHandle.frame.minY
        let initialTitleY = sheetTitle.frame.minY
        let initialCloseY = closeButton.frame.minY
        let initialSaveY = saveButton.frame.minY

        memo.tap()
        XCTAssertTrue(app.buttons["feeding.memo.done"].waitForExistence(timeout: 3))
        let keyboard = app.keyboards.firstMatch
        XCTAssertTrue(keyboard.waitForExistence(timeout: 5))
        XCTAssertEqual(sheetHandle.frame.minY, initialHandleY, accuracy: 1)
        XCTAssertEqual(sheetTitle.frame.minY, initialTitleY, accuracy: 1)
        XCTAssertEqual(closeButton.frame.minY, initialCloseY, accuracy: 1)
        XCTAssertEqual(saveButton.frame.minY, initialSaveY, accuracy: 1)

        let clearMemo = app.buttons["feeding.memo.clear"]
        XCTAssertTrue(clearMemo.waitForExistence(timeout: 3))
        let clearMemoIsHittable = XCTNSPredicateExpectation(
            predicate: NSPredicate(format: "hittable == true"),
            object: clearMemo
        )
        XCTAssertEqual(XCTWaiter.wait(for: [clearMemoIsHittable], timeout: 5), .completed)
        XCTAssertLessThan(clearMemo.frame.maxY, keyboard.frame.minY, "Memo clear control must sit above the keyboard")
        clearMemo.tap()

        let attemptedMemo = String(repeating: "a", count: 320)
        let expectedMemo = String(attemptedMemo.prefix(300))
        memo.typeText(attemptedMemo)

        let memoCappedExpectation = XCTNSPredicateExpectation(
            predicate: NSPredicate(format: "value == %@", expectedMemo),
            object: memo
        )
        XCTAssertEqual(XCTWaiter.wait(for: [memoCappedExpectation], timeout: 3), .completed)
        XCTAssertEqual(memo.value as? String, expectedMemo)
        XCTAssertEqual(expectedMemo.count, 300)
        XCTAssertGreaterThan(memo.frame.height, initialHeight + 20)
    }

    func testCreatureDetailFeedingPreviewShowsFigmaContentAndSupportsEditing() {
        let app = XCUIApplication()
        app.launchArguments.append("--preview-creature-detail-feeding")
        app.launch()

        let scrollView = app.scrollViews["creatureDetail.scroll"]
        XCTAssertTrue(scrollView.waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["욱이"].exists)
        XCTAssertTrue(app.staticTexts["creatureDetail.description"].exists)
        XCTAssertTrue(app.staticTexts["급여 기록"].exists)
        XCTAssertTrue(app.staticTexts["직전 기록으로 채웠어요"].exists)

        let feeding = app.buttons["creatureDetail.category.급여"]
        let molting = app.buttons["creatureDetail.category.탈피"]
        XCTAssertEqual(feeding.value as? String, "선택됨")
        molting.tap()
        let unavailableNotice = app.alerts["준비 중"]
        XCTAssertTrue(unavailableNotice.waitForExistence(timeout: 3))
        XCTAssertTrue(unavailableNotice.staticTexts["탈피 기록은 준비 중이에요."].exists)
        XCTAssertEqual(feeding.value as? String, "선택됨")
        unavailableNotice.buttons["확인"].tap()

        let cricket = app.buttons["creatureDetail.food.귀뚜라미"]
        let mealworm = app.buttons["creatureDetail.food.밀웜"]
        XCTAssertTrue(cricket.waitForExistence(timeout: 3))
        XCTAssertEqual(cricket.value as? String, "선택됨")
        mealworm.tap()
        XCTAssertEqual(mealworm.value as? String, "선택됨")

        let quantity = app.staticTexts["creatureDetail.quantity.value"]
        XCTAssertEqual(quantity.label, "50")
        app.buttons["creatureDetail.quantity.decrease"].tap()
        XCTAssertEqual(quantity.label, "49")
        app.buttons["creatureDetail.quantity.increase"].tap()
        XCTAssertEqual(quantity.label, "50")

        let notEaten = app.buttons["creatureDetail.notEaten"]
        XCTAssertEqual(notEaten.value as? String, "끔")
        notEaten.tap()
        XCTAssertEqual(notEaten.value as? String, "켬")
        notEaten.tap()

        let memo = app.textFields["creatureDetail.memo"]
        for _ in 0..<5 where !memo.isHittable {
            scrollView.swipeUp()
        }
        XCTAssertTrue(memo.waitForExistence(timeout: 3))
        XCTAssertEqual(memo.value as? String, "잘 받아먹음")
        memo.tap()
        XCTAssertTrue(app.keyboards.firstMatch.waitForExistence(timeout: 5))
        let clearMemo = app.buttons["creatureDetail.memo.clear"]
        XCTAssertTrue(clearMemo.waitForExistence(timeout: 3))
        XCTAssertTrue(clearMemo.isHittable)
        clearMemo.tap()
        memo.typeText("잘 먹었어요")
        XCTAssertEqual(memo.value as? String, "잘 먹었어요")
        app.buttons["creatureDetail.memo.done"].tap()

        let memoAttachment = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        memoAttachment.name = "05-a memo form on iPhone 17e"
        memoAttachment.lifetime = .keepAlways
        add(memoAttachment)

        let cancel = app.buttons["creatureDetail.cancel"]
        for _ in 0..<5 where !cancel.isHittable {
            scrollView.swipeUp()
        }
        XCTAssertTrue(cancel.isHittable)
        cancel.tap()
        XCTAssertEqual(quantity.label, "50")
        XCTAssertEqual(app.buttons["creatureDetail.food.귀뚜라미"].value as? String, "선택됨")
    }

    func testCreatureDetailDateSaveAndLowerSections() {
        let app = XCUIApplication()
        app.launchArguments.append("--preview-creature-detail-feeding")
        app.launch()

        let scrollView = app.scrollViews["creatureDetail.scroll"]
        XCTAssertTrue(scrollView.waitForExistence(timeout: 5))

        let date = app.buttons["creatureDetail.date"]
        XCTAssertTrue(date.waitForExistence(timeout: 3))
        date.tap()
        XCTAssertTrue(app.staticTexts["날짜 선택"].waitForExistence(timeout: 3))
        let dateDone = app.buttons["creatureDetail.date.done"]
        XCTAssertTrue(dateDone.isHittable)
        dateDone.tap()

        let save = app.buttons["creatureDetail.save"]
        for _ in 0..<5 where !save.isHittable {
            scrollView.swipeUp()
        }
        XCTAssertTrue(save.isHittable)
        save.tap()
        let savePreview = app.alerts["저장 미리보기"]
        XCTAssertTrue(savePreview.waitForExistence(timeout: 3))
        savePreview.buttons["확인"].tap()

        let chart = app.otherElements["creatureDetail.weightChart"]
        for _ in 0..<6 where !chart.isHittable {
            scrollView.swipeUp()
        }
        XCTAssertTrue(chart.waitForExistence(timeout: 3))
        XCTAssertTrue(app.staticTexts["체중 변화"].exists)
        XCTAssertTrue(app.staticTexts["최근 기록"].exists)

        let firstRecord = app.buttons["creatureDetail.record.delete.weight-1020"]
        if !firstRecord.isHittable {
            scrollView.swipeUp()
        }
        XCTAssertTrue(firstRecord.waitForExistence(timeout: 3))
        firstRecord.tap()
        XCTAssertFalse(firstRecord.exists)

        let album = app.buttons["creatureDetail.management.0"]
        for _ in 0..<5 where !album.isHittable {
            scrollView.swipeUp()
        }
        XCTAssertTrue(album.waitForExistence(timeout: 3))

        let lowerContentAttachment = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        lowerContentAttachment.name = "05-a lower sections on iPhone 17e"
        lowerContentAttachment.lifetime = .keepAlways
        add(lowerContentAttachment)

        album.tap()
        XCTAssertTrue(app.alerts["준비 중"].waitForExistence(timeout: 3))
    }
}
