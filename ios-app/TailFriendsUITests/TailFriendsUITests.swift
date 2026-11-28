import XCTest

final class TailFriendsUITests: XCTestCase {
    func testHabitatThemePreviewShowsCurrentAndUnavailableThemes() {
        let app = XCUIApplication()
        app.launchArguments.append("--preview-habitat-theme")
        app.launch()

        XCTAssertTrue(app.staticTexts["사육장 테마"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["개체 상세 맨 위 사육장 배경이 바뀌어요"].exists)
        XCTAssertTrue(app.buttons["habitatTheme.desert"].exists)
        XCTAssertTrue(app.buttons["habitatTheme.rainforest"].exists)
        XCTAssertEqual(app.buttons["habitatTheme.desert"].label, "사막, 사용 중")

        app.buttons["habitatTheme.rainforest"].tap()
        XCTAssertTrue(app.staticTexts["habitatTheme.toast"].waitForExistence(timeout: 2))
    }

    func testNotificationSettingsPreviewUpdatesTogglesAndOpensTimePickers() {
        let app = XCUIApplication()
        app.launchArguments.append("--preview-notification-settings")
        app.launch()

        let feeding = app.switches["notification.feeding"]
        let shedding = app.switches["notification.shedding"]
        let weight = app.switches["notification.weight"]
        let growthNews = app.switches["notification.growthNews"]
        let events = app.switches["notification.events"]

        XCTAssertTrue(app.staticTexts["알림 설정"].waitForExistence(timeout: 5))
        XCTAssertEqual(feeding.value as? String, "1")
        XCTAssertEqual(shedding.value as? String, "1")
        XCTAssertEqual(weight.value as? String, "0")
        XCTAssertEqual(growthNews.value as? String, "1")
        XCTAssertEqual(events.value as? String, "0")

        weight.tap()
        XCTAssertEqual(weight.value as? String, "1")
        events.tap()
        XCTAssertEqual(events.value as? String, "1")

        app.buttons["notification.feedingTime"].tap()
        XCTAssertTrue(app.datePickers["notification.time.feedingPicker"].waitForExistence(timeout: 3))
        app.buttons["notification.time.done"].tap()

        app.buttons["notification.quietHours"].tap()
        XCTAssertTrue(app.datePickers["notification.time.quietStartPicker"].waitForExistence(timeout: 3))
        XCTAssertTrue(app.datePickers["notification.time.quietEndPicker"].exists)
        app.buttons["notification.time.done"].tap()
    }

    func testRecordListPreviewFiltersRecordsAndReturnsHome() {
        let app = XCUIApplication()
        app.launchArguments.append("--preview-record-list")
        app.launch()

        XCTAssertTrue(app.staticTexts["recordList.title"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["오늘 · 10월 20일"].exists)
        XCTAssertTrue(app.buttons["recordList.record.weight-1020"].exists)
        XCTAssertTrue(app.buttons["recordList.record.feeding-1020"].exists)

        app.buttons["recordList.filter.weight"].tap()
        XCTAssertTrue(app.buttons["recordList.record.weight-1020"].exists)
        XCTAssertFalse(app.buttons["recordList.record.feeding-1020"].exists)
        XCTAssertTrue(app.staticTexts["10월 13일"].exists)

        app.buttons["recordList.filter.memo"].tap()
        XCTAssertTrue(app.buttons["recordList.record.feeding-1017"].exists)
        XCTAssertTrue(app.buttons["recordList.record.shedding-1008"].exists)
        XCTAssertFalse(app.buttons["recordList.record.weight-1020"].exists)

        app.buttons["recordList.back"].tap()
        XCTAssertTrue(app.staticTexts["오늘의 사육장"].waitForExistence(timeout: 5))
    }

    func testRecordListFriendSelectionOpensAndUpdatesTemporarySelection() {
        let app = XCUIApplication()
        app.launchArguments.append("--preview-record-list")
        app.launch()

        let petSelector = app.buttons["recordList.petSelector"]
        XCTAssertTrue(petSelector.waitForExistence(timeout: 5))
        petSelector.tap()

        XCTAssertTrue(app.staticTexts["friendSelection.title"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["friendSelection.subtitle"].exists)
        XCTAssertTrue(app.buttons["friendSelection.all"].exists)
        XCTAssertEqual(
            app.staticTexts["friendSelection.title"].frame.minX,
            app.staticTexts["friendSelection.subtitle"].frame.minX,
            accuracy: 1
        )
        XCTAssertEqual(app.buttons["friendSelection.friend.yukyi"].value as? String, "선택됨")

        let chito = app.buttons["friendSelection.friend.chito"]
        XCTAssertTrue(chito.isHittable)
        chito.tap()
        XCTAssertEqual(chito.value as? String, "선택됨")
        XCTAssertEqual(app.buttons["friendSelection.friend.yukyi"].value as? String, "선택 안 됨")
        XCTAssertEqual(petSelector.label, "친구 치토 선택")

        let friendScroll = app.scrollViews["friendSelection.scroll"]
        friendScroll.swipeUp()
        XCTAssertTrue(app.buttons["friendSelection.friend.haru"].isHittable)

        app.buttons["friendSelection.close"].tap()
        XCTAssertTrue(app.staticTexts["recordList.title"].waitForExistence(timeout: 5))
        XCTAssertEqual(petSelector.label, "친구 치토 선택")
        XCTAssertEqual(
            app.staticTexts["recordList.empty"].waitForExistence(timeout: 5) ? app.staticTexts["recordList.empty"].label : nil,
            "아직 기록이 없어요"
        )
        XCTAssertFalse(app.buttons["recordList.record.feeding-1017"].exists)

        petSelector.tap()
        XCTAssertTrue(app.staticTexts["friendSelection.title"].waitForExistence(timeout: 5))
        app.buttons["friendSelection.friend.yukyi"].tap()
        app.buttons["friendSelection.close"].tap()
        XCTAssertEqual(petSelector.label, "친구 육이 선택")
        XCTAssertTrue(app.buttons["recordList.record.feeding-1017"].waitForExistence(timeout: 5))

        petSelector.tap()
        XCTAssertTrue(app.staticTexts["friendSelection.title"].waitForExistence(timeout: 5))
        let allFriends = app.buttons["friendSelection.all"]
        allFriends.tap()
        XCTAssertEqual(allFriends.value as? String, "선택됨")

        let selectionScroll = app.scrollViews["friendSelection.scroll"]
        for friendID in ["yukyi", "chito", "leo", "sera"] {
            XCTAssertEqual(app.buttons["friendSelection.friend.\(friendID)"].value as? String, "선택됨")
        }
        selectionScroll.swipeUp()
        for friendID in ["toto", "ruby", "haru"] {
            XCTAssertEqual(app.buttons["friendSelection.friend.\(friendID)"].value as? String, "선택됨")
        }

        app.buttons["friendSelection.close"].tap()
        XCTAssertEqual(petSelector.label, "친구 전체 친구 선택")
        XCTAssertTrue(app.buttons["recordList.record.feeding-1017"].waitForExistence(timeout: 5))

        petSelector.tap()
        XCTAssertTrue(app.staticTexts["friendSelection.title"].waitForExistence(timeout: 5))
        let allFriendsToClear = app.buttons["friendSelection.all"]
        XCTAssertEqual(allFriendsToClear.value as? String, "선택됨")
        allFriendsToClear.tap()
        XCTAssertEqual(allFriendsToClear.value as? String, "선택 안 됨")
        let noneSelectionScroll = app.scrollViews["friendSelection.scroll"]
        for friendID in ["yukyi", "chito", "leo", "sera"] {
            XCTAssertEqual(app.buttons["friendSelection.friend.\(friendID)"].value as? String, "선택 안 됨")
        }
        noneSelectionScroll.swipeUp()
        for friendID in ["toto", "ruby", "haru"] {
            XCTAssertEqual(app.buttons["friendSelection.friend.\(friendID)"].value as? String, "선택 안 됨")
        }
        app.buttons["friendSelection.close"].tap()
        XCTAssertEqual(petSelector.label, "선택된 친구 없음")
        XCTAssertEqual(app.staticTexts["recordList.empty"].waitForExistence(timeout: 5) ? app.staticTexts["recordList.empty"].label : nil, "아직 기록이 없어요")
        XCTAssertFalse(app.buttons["recordList.record.feeding-1017"].exists)

        petSelector.tap()
        XCTAssertTrue(app.staticTexts["friendSelection.title"].waitForExistence(timeout: 5))
        let reselectAllFriends = app.buttons["friendSelection.all"]
        XCTAssertEqual(reselectAllFriends.value as? String, "선택 안 됨")
        reselectAllFriends.tap()
        XCTAssertEqual(reselectAllFriends.value as? String, "선택됨")
        let reselectScroll = app.scrollViews["friendSelection.scroll"]
        for friendID in ["yukyi", "chito", "leo", "sera"] {
            XCTAssertEqual(app.buttons["friendSelection.friend.\(friendID)"].value as? String, "선택됨")
        }
        reselectScroll.swipeUp()
        for friendID in ["toto", "ruby", "haru"] {
            XCTAssertEqual(app.buttons["friendSelection.friend.\(friendID)"].value as? String, "선택됨")
        }
        app.buttons["friendSelection.close"].tap()
        XCTAssertEqual(petSelector.label, "친구 전체 친구 선택")
        XCTAssertTrue(app.buttons["recordList.record.feeding-1017"].waitForExistence(timeout: 5))
    }

    func testFeedingRecordEditLoadsSelectedRecordAndSavesChangesToList() {
        let app = XCUIApplication()
        app.launchArguments.append("--preview-record-list")
        app.launch()

        let feedingRecord = app.buttons["recordList.record.feeding-1017"]
        XCTAssertTrue(feedingRecord.waitForExistence(timeout: 5))
        feedingRecord.tap()

        XCTAssertTrue(app.staticTexts["feedingEdit.title"].waitForExistence(timeout: 5))
        XCTAssertEqual(app.buttons["feedingEdit.date"].label, "날짜, 10월 17일 (토)")
        XCTAssertEqual(app.buttons["feedingEdit.food.귀뚜라미"].value as? String, "선택됨")
        XCTAssertEqual(app.staticTexts["feedingEdit.quantity.value"].label, "50")

        let memo = app.descendants(matching: .any)["feedingEdit.memo"]
        XCTAssertEqual(memo.value as? String, "잘 받아먹음")

        app.buttons["feedingEdit.date"].tap()
        XCTAssertTrue(app.buttons["feedingEdit.date.done"].waitForExistence(timeout: 3))
        app.buttons["feedingEdit.date.done"].tap()

        app.buttons["feedingEdit.food.밀웜"].tap()
        app.buttons["feedingEdit.quantity.increase"].tap()
        app.buttons["feedingEdit.notEaten"].tap()
        XCTAssertEqual(app.buttons["feedingEdit.notEaten"].value as? String, "켬")

        app.buttons["feedingEdit.save"].tap()
        XCTAssertTrue(
            app.staticTexts["recordList.title"].waitForExistence(timeout: 5),
            "Saving should return to the record list. Current screen: \(app.debugDescription)"
        )
        XCTAssertTrue(
            feedingRecord.waitForExistence(timeout: 5),
            "The edited feeding row should remain visible. Current screen: \(app.debugDescription)"
        )
        let updatedLabel = feedingRecord.label
        XCTAssertTrue(updatedLabel.contains("밀웜"), updatedLabel)
        XCTAssertTrue(updatedLabel.contains("안 먹음"), updatedLabel)
        XCTAssertTrue(updatedLabel.contains("잘 받아먹음"), updatedLabel)

        feedingRecord.tap()
        XCTAssertEqual(app.staticTexts["feedingEdit.quantity.value"].label, "51")
        XCTAssertEqual(app.buttons["feedingEdit.notEaten"].value as? String, "켬")
    }

    func testCareWeeklyPreviewSupportsDaySelectionAndCalendarNavigation() {
        let app = XCUIApplication()
        app.launchArguments.append("--preview-care-dial")
        app.launch()

        let weekButton = app.buttons["careDial.period.주간"]
        XCTAssertTrue(weekButton.waitForExistence(timeout: 5))
        weekButton.tap()

        XCTAssertTrue(app.staticTexts["careWeekly.headline"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["careWeekly.dateRange"].exists)
        XCTAssertTrue(app.staticTexts["careWeekly.recordedDays"].exists)
        XCTAssertTrue(app.staticTexts["careWeekly.nextShedding"].exists)

        let selectedDay = app.buttons["careWeekly.day.20"]
        let anotherDay = app.buttons["careWeekly.day.17"]
        XCTAssertTrue(selectedDay.exists)
        XCTAssertTrue(anotherDay.exists)
        XCTAssertEqual(selectedDay.value as? String, "선택됨")

        anotherDay.tap()
        XCTAssertEqual(anotherDay.value as? String, "선택됨")
        XCTAssertEqual(selectedDay.value as? String, "선택 안 됨")

        app.buttons["careWeekly.calendar"].tap()
        XCTAssertTrue(app.staticTexts["careCalendar.month"].waitForExistence(timeout: 5))
        XCTAssertEqual(app.staticTexts["careCalendar.month"].label, "2026년 10월")
        app.buttons["careCalendar.back"].tap()
        XCTAssertTrue(app.staticTexts["careWeekly.headline"].waitForExistence(timeout: 5))

        app.buttons["careWeekly.period.today"].tap()
        XCTAssertTrue(app.staticTexts["careDial.headline"].waitForExistence(timeout: 5))
    }

    func testCareCalendarPreviewSelectsDaysAndNavigatesMonths() {
        let app = XCUIApplication()
        app.launchArguments.append("--preview-care-calendar")
        app.launch()

        let month = app.staticTexts["careCalendar.month"]
        XCTAssertTrue(month.waitForExistence(timeout: 5))
        XCTAssertEqual(month.label, "2026년 10월")
        XCTAssertEqual(app.staticTexts["careCalendar.selectedDate"].label, "10월 20일 화요일")
        XCTAssertEqual(app.staticTexts["careCalendar.record.weight.detail"].label, "53.4g · +1.4g")
        XCTAssertEqual(app.staticTexts["careCalendar.record.feeding.detail"].label, "귀뚜라미 50마리 · 칼슘")

        let selectedDay = app.buttons["careCalendar.day.20"]
        let anotherDay = app.buttons["careCalendar.day.21"]
        XCTAssertEqual(selectedDay.value as? String, "선택됨")
        anotherDay.tap()
        XCTAssertEqual(anotherDay.value as? String, "선택됨")
        XCTAssertEqual(selectedDay.value as? String, "선택 안 됨")
        XCTAssertEqual(app.staticTexts["careCalendar.selectedDate"].label, "10월 21일 수요일")
        XCTAssertTrue(app.staticTexts["careCalendar.emptyRecords"].exists)

        app.buttons["careCalendar.month.previous"].tap()
        XCTAssertEqual(month.label, "2026년 9월")
        XCTAssertEqual(app.staticTexts["careCalendar.selectedDate"].label, "9월 21일 월요일")
        app.buttons["careCalendar.month.next"].tap()
        XCTAssertEqual(month.label, "2026년 10월")

        app.buttons["careCalendar.day.20"].tap()
        app.buttons["careCalendar.today"].tap()

        var calendar = Calendar(identifier: .gregorian)
        calendar.locale = Locale(identifier: "ko_KR")
        let today = calendar.startOfDay(for: Date())
        let dateFormatter = DateFormatter()
        dateFormatter.locale = Locale(identifier: "ko_KR")
        dateFormatter.calendar = calendar
        dateFormatter.dateFormat = "M월 d일 EEEE"
        XCTAssertEqual(app.staticTexts["careCalendar.selectedDate"].label, dateFormatter.string(from: today))
    }

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

    func testCreatureListEmptyPreviewShowsFigmaCopyAndRegistrationFlow() {
        let app = XCUIApplication()
        app.launchArguments.append("--preview-creature-list-empty")
        app.launch()

        XCTAssertTrue(app.staticTexts["creatureList.title"].waitForExistence(timeout: 5))
        XCTAssertEqual(app.staticTexts["creatureList.sortCount"].label, "등록순 · 7마리")
        XCTAssertTrue(app.staticTexts["creatureList.empty.title"].exists)
        XCTAssertTrue(app.staticTexts["creatureList.empty.subtitle"].exists)

        let listMode = app.buttons["creatureList.mode.list"]
        XCTAssertTrue(listMode.exists)
        XCTAssertEqual(listMode.value as? String, "선택됨")

        let wheelMode = app.buttons["creatureList.mode.wheel"]
        XCTAssertTrue(wheelMode.exists)
        XCTAssertTrue(wheelMode.isEnabled)
        wheelMode.tap()
        XCTAssertEqual(wheelMode.value as? String, "선택됨")
        XCTAssertEqual(listMode.value as? String, "선택 안 됨")
        listMode.tap()
        XCTAssertEqual(listMode.value as? String, "선택됨")

        let selectedTab = app.descendants(matching: .any)
            .matching(identifier: "creatureList.bottomNavigation.pets")
            .firstMatch
        XCTAssertTrue(selectedTab.exists)
        XCTAssertTrue(selectedTab.isSelected)

        app.buttons["creatureList.empty.register"].tap()
        XCTAssertTrue(app.staticTexts["새 친구 등록"].waitForExistence(timeout: 5))
        app.buttons["registration.header"].tap()

        app.buttons["creatureList.registration.plus"].tap()
        XCTAssertTrue(app.staticTexts["새 친구 등록"].waitForExistence(timeout: 5))
    }

    func testCreatureListLoadingPreviewShowsSixSkeletonCards() {
        let app = XCUIApplication()
        app.launchArguments = [
            "--preview-creature-list-loading",
            "--preview-creature-list-loading-static"
        ]
        app.launch()

        XCTAssertTrue(app.staticTexts["creatureListLoading.title"].waitForExistence(timeout: 5))
        XCTAssertEqual(app.staticTexts["creatureListLoading.sortCount"].label, "등록순 · 7마리")
        XCTAssertTrue(app.descendants(matching: .any)["creatureListLoading.skeletonList"].exists)

        for index in 0..<6 {
            XCTAssertTrue(app.descendants(matching: .any)["creatureListLoading.skeleton.\(index)"].exists)
        }

        let wheelMode = app.buttons["creatureListLoading.mode.wheel"]
        XCTAssertTrue(wheelMode.waitForExistence(timeout: 3))
        wheelMode.tap()
        XCTAssertEqual(wheelMode.value as? String, "선택됨")
    }

    func testCreatureListLoadingPreviewTransitionsToSevenMockCards() {
        let app = XCUIApplication()
        app.launchArguments.append("--preview-creature-list-loading")
        app.launch()

        let firstName = app.staticTexts["creatureListLoading.card.1.name"]
        XCTAssertTrue(firstName.waitForExistence(timeout: 6))
        XCTAssertEqual(firstName.label, "욱이")
        XCTAssertEqual(app.staticTexts["creatureListLoading.card.1.species"].label, "레오파드 게코 · 탠저린")
        XCTAssertEqual(app.staticTexts["creatureListLoading.card.1.weight"].label, "53.4g")
        XCTAssertTrue(app.staticTexts["creatureListLoading.status.todayFeeding"].exists)

        XCTAssertEqual(app.staticTexts["creatureListLoading.card.2.name"].label, "치토")
        XCTAssertTrue(app.staticTexts["creatureListLoading.status.weightDrop"].exists)
        XCTAssertEqual(app.staticTexts["creatureListLoading.card.3.name"].label, "레오")
        XCTAssertEqual(app.staticTexts["creatureListLoading.card.4.name"].label, "세라")
        XCTAssertEqual(app.staticTexts["creatureListLoading.card.5.name"].label, "토토")
        XCTAssertEqual(app.staticTexts["creatureListLoading.card.6.name"].label, "루비")
        XCTAssertEqual(app.staticTexts["creatureListLoading.card.7.name"].label, "하루")
        XCTAssertTrue(app.staticTexts["creatureListLoading.card.7.weightLabel"].exists)
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
        let intervalWasCleared = XCTNSPredicateExpectation(
            predicate: NSPredicate(format: "value != %@", "4"),
            object: feedingInterval
        )
        XCTAssertEqual(XCTWaiter.wait(for: [intervalWasCleared], timeout: 2), .completed)
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
        XCTAssertEqual(memo.value as? String, memo.placeholderValue)

        let expectedMemo = String(repeating: "a", count: 120)
        memo.typeText(expectedMemo)

        let memoValueExpectation = XCTNSPredicateExpectation(
            predicate: NSPredicate(format: "value == %@", expectedMemo),
            object: memo
        )
        XCTAssertEqual(XCTWaiter.wait(for: [memoValueExpectation], timeout: 5), .completed)
        XCTAssertEqual(memo.value as? String, expectedMemo)
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

        let feedingFormCard = app.descendants(matching: .any)
            .matching(identifier: "creatureDetail.feedingForm")
            .firstMatch
        XCTAssertTrue(feedingFormCard.waitForExistence(timeout: 3))
        XCTAssertEqual(feedingFormCard.frame.minX, 24, accuracy: 1)
        XCTAssertEqual(feedingFormCard.frame.maxX, scrollView.frame.maxX - 24, accuracy: 1)

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
        let memoClearedExpectation = XCTNSPredicateExpectation(
            predicate: NSPredicate(format: "value != %@", "잘 받아먹음"),
            object: memo
        )
        XCTAssertEqual(XCTWaiter.wait(for: [memoClearedExpectation], timeout: 3), .completed)
        let memoValueAfterClear = memo.value as? String ?? ""
        XCTAssertTrue(memoValueAfterClear.isEmpty || memoValueAfterClear == "메모를 입력해 주세요")
        memo.tap()
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

    func testCreatureDetailPreviewBackReturnsToHome() {
        let app = XCUIApplication()
        app.launchArguments.append("--preview-creature-detail-feeding")
        app.launch()

        let detailScroll = app.scrollViews["creatureDetail.scroll"]
        XCTAssertTrue(detailScroll.waitForExistence(timeout: 5))
        app.buttons["creatureDetail.back"].tap()

        XCTAssertTrue(app.staticTexts["오늘의 사육장"].waitForExistence(timeout: 5))
        XCTAssertFalse(detailScroll.exists)
    }

    func testCreatureDetailRecordEmptyPreviewShowsFigmaStateAndInteractions() {
        let app = XCUIApplication()
        app.launchArguments.append("--preview-creature-detail-record-empty")
        app.launch()

        let scrollView = app.scrollViews["creatureDetailRecordEmpty.scroll"]
        XCTAssertTrue(scrollView.waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["욱이"].exists)
        XCTAssertTrue(app.staticTexts["creatureDetailRecordEmpty.description"].exists)
        XCTAssertEqual(
            app.staticTexts["creatureDetailRecordEmpty.metric.feeding.value"].label,
            "기록 없음"
        )
        XCTAssertEqual(
            app.staticTexts["creatureDetailRecordEmpty.metric.molting.value"].label,
            "기록 없음"
        )
        XCTAssertEqual(
            app.staticTexts["creatureDetailRecordEmpty.metric.weight.value"].label,
            "기록 없음"
        )

        let feeding = app.buttons["creatureDetailRecordEmpty.category.급여"]
        XCTAssertEqual(feeding.value as? String, "선택 안 됨")
        feeding.tap()
        XCTAssertEqual(feeding.value as? String, "선택됨")

        let emptyRecordTitle = app.staticTexts["creatureDetailRecordEmpty.records.empty.title"]
        for _ in 0..<8 where !emptyRecordTitle.isHittable {
            scrollView.swipeUp()
        }
        XCTAssertTrue(emptyRecordTitle.waitForExistence(timeout: 3))
        XCTAssertEqual(emptyRecordTitle.label, "아직 기록이 없어요")
        XCTAssertTrue(app.staticTexts["creatureDetailRecordEmpty.records.empty.message"].exists)
        XCTAssertTrue(app.staticTexts["creatureDetailRecordEmpty.weightChart.empty"].exists)

        let showAll = app.buttons["creatureDetailRecordEmpty.records.all"]
        XCTAssertTrue(showAll.isHittable)
        showAll.tap()
        let noRecordsNotice = app.alerts["최근 기록"]
        XCTAssertTrue(noRecordsNotice.waitForExistence(timeout: 3))
        noRecordsNotice.buttons["확인"].tap()

        let album = app.buttons["creatureDetailRecordEmpty.management.0"]
        for _ in 0..<4 where !album.isHittable {
            scrollView.swipeUp()
        }
        XCTAssertTrue(album.waitForExistence(timeout: 3))

        let screenshot = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        screenshot.name = "05-c empty record detail on iPhone 17e"
        screenshot.lifetime = .keepAlways
        add(screenshot)

        album.tap()
        XCTAssertTrue(app.alerts["준비 중"].waitForExistence(timeout: 3))
        app.alerts["준비 중"].buttons["확인"].tap()

        let back = app.buttons["creatureDetailRecordEmpty.back"]
        for _ in 0..<8 where !back.isHittable {
            scrollView.swipeDown()
        }
        back.tap()
        XCTAssertTrue(app.staticTexts["오늘의 사육장"].waitForExistence(timeout: 5))
    }

    func testCreatureDetailHealthWarningPreviewShowsRecordBasedWarningAndActions() {
        let app = XCUIApplication()
        app.launchArguments.append("--preview-creature-detail-health-warning")
        app.launch()

        let scrollView = app.scrollViews["creatureDetailRecordDelete.scroll"]
        XCTAssertTrue(scrollView.waitForExistence(timeout: 5))

        let warningTitle = app.staticTexts["creatureDetailRecordDelete.healthWarning.title"]
        XCTAssertTrue(warningTitle.waitForExistence(timeout: 3))
        XCTAssertEqual(warningTitle.label, "거식 경고 · 3번 연속 안 먹었어요")
        XCTAssertEqual(
            app.staticTexts["creatureDetailRecordDelete.healthWarning.dates"].label,
            "10/12 · 10/16 · 10/20"
        )
        let feedingMetric = app.staticTexts["creatureDetailRecordDelete.metric.다음 급여"]
        XCTAssertTrue(feedingMetric.label.contains("8일 지남"))
        let weightMetric = app.staticTexts["creatureDetailRecordDelete.metric.체중"]
        XCTAssertTrue(weightMetric.label.contains("52.1g"))

        let screenshot = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        screenshot.name = "05-d health warning on iPhone 17e"
        screenshot.lifetime = .keepAlways
        add(screenshot)

        let dismissWarning = app.buttons["creatureDetailRecordDelete.healthWarning.dismiss"]
        let vetRecord = app.buttons["creatureDetailRecordDelete.healthWarning.vetRecord"]
        let guide = app.buttons["creatureDetailRecordDelete.healthWarning.guide"]
        for action in [dismissWarning, vetRecord, guide] {
            XCTAssertTrue(action.isHittable)
            XCTAssertGreaterThanOrEqual(action.frame.width, 44)
            XCTAssertGreaterThanOrEqual(action.frame.height, 44)
        }

        vetRecord.tap()
        let vetNotice = app.alerts["준비 중"]
        XCTAssertTrue(vetNotice.waitForExistence(timeout: 3))
        XCTAssertTrue(vetNotice.staticTexts["진료 기록은 준비 중이에요."].exists)
        vetNotice.buttons["확인"].tap()

        guide.tap()
        let guideNotice = app.alerts["준비 중"]
        XCTAssertTrue(guideNotice.waitForExistence(timeout: 3))
        XCTAssertTrue(guideNotice.staticTexts["사육 가이드는 준비 중이에요."].exists)
        guideNotice.buttons["확인"].tap()

        dismissWarning.tap()
        XCTAssertFalse(warningTitle.exists)
    }
}
