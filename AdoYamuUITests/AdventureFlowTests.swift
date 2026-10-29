import XCTest

final class AdventureFlowTests: XCTestCase {
    private var app: XCUIApplication!
    override func setUp() {
        continueAfterFailure = false
        app = XCUIApplication(); app.launchArguments = ["--uitesting"]; app.launch()
    }
    private func capture(_ name: String, settle: TimeInterval = 0.5) {
        Thread.sleep(forTimeInterval: settle)
        let attachment = XCTAttachment(screenshot: app.screenshot()); attachment.name = name; attachment.lifetime = .keepAlways; add(attachment)
    }
    private func start() {
        XCTAssertTrue(app.buttons["getStarted"].waitForExistence(timeout: 10)); app.buttons["getStarted"].tap()
        XCTAssertTrue(app.buttons["tab-explore"].waitForExistence(timeout: 5))
    }
    private func scrollTo(_ element: XCUIElement, bottomInset: CGFloat = 0) {
        for _ in 0..<16 {
            let modes = app.buttons["Offline ideas"]
            let nav = app.navigationBars.firstMatch
            let top = modes.exists ? modes.frame.maxY + 8 : nav.exists ? nav.frame.maxY + 8 : app.frame.minY + 50
            let bottom = app.frame.maxY - bottomInset
            var scrollDown = false
            if element.exists {
                let frame = element.frame
                if element.isHittable && frame.minY >= top && frame.maxY <= bottom { return }
                scrollDown = frame.minY < top
            }
            let scroll = app.scrollViews.firstMatch
            let upper = scroll.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.35))
            let lower = scroll.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.65))
            if scrollDown { upper.press(forDuration: 0.05, thenDragTo: lower) }
            else { lower.press(forDuration: 0.05, thenDragTo: upper) }
        }
        XCTFail("Could not scroll the control clear of the fixed header/footer: \(element)")
    }
    func testWelcomeHomeExploreFavoritesVisitAndPassport() {
        XCTAssertTrue(app.buttons["getStarted"].waitForExistence(timeout: 10))
        capture("01-Welcome"); start(); capture("02-Home")
        app.buttons["tab-explore"].tap()
        let search = app.textFields["placeSearch"]; XCTAssertTrue(search.waitForExistence(timeout: 5))
        search.tap(); search.typeText("Nine Arches\n")
        XCTAssertTrue(app.buttons["favorite-bridge"].waitForExistence(timeout: 5)); capture("08-Explore-search")
        app.buttons["favorite-bridge"].tap()
        app.buttons["tab-saved"].tap(); XCTAssertTrue(app.staticTexts["Nine Arches Bridge"].waitForExistence(timeout: 5)); capture("09-Saved")
        app.staticTexts["Nine Arches Bridge"].tap(); capture("05-Details")
        let visit = app.buttons["markVisited"]; scrollTo(visit); XCTAssertTrue(visit.isHittable); visit.tap()
        XCTAssertTrue(app.buttons["Keep exploring"].waitForExistence(timeout: 5)); capture("07-New-stamp"); app.buttons["Keep exploring"].tap()
        app.buttons["Back"].firstMatch.tap()
        app.buttons["tab-profile"].tap(); capture("10-Profile")
        app.buttons["openPassport"].tap(); XCTAssertTrue(app.staticTexts["1 of 18 places explored"].waitForExistence(timeout: 5)); capture("07-Passport")
    }

    func testSplashReturnsWhenReopeningAfterOnboarding() {
        start()
        app.buttons["tab-saved"].tap()
        XCTAssertTrue(app.staticTexts["Saved Places"].waitForExistence(timeout: 5))

        XCUIDevice.shared.press(.home)
        app.activate()

        let splash = app.staticTexts["launchSplash"]
        XCTAssertTrue(splash.waitForExistence(timeout: 2))
        XCTAssertFalse(app.buttons["getStarted"].exists)
        capture("Launch-splash-without-button", settle: 0.1)
        XCTAssertTrue(app.buttons["tab-home"].waitForExistence(timeout: 5))
        XCTAssertFalse(splash.exists)
        XCTAssertFalse(app.buttons["getStarted"].exists)
        // Returning from the splash preserves the user's current tab.
        XCTAssertTrue(app.staticTexts["Saved Places"].exists)
    }
    func testPlannerFindsLocalMatchAndMapOpens() {
        start(); app.buttons["tab-surprise"].tap(); app.buttons["Offline ideas"].tap(); capture("03-Planner")
        let find = app.buttons["findAdventure"]; scrollTo(find); find.tap(); capture("04-Finding", settle: 0.1)
        XCTAssertTrue(app.buttons["markVisited"].waitForExistence(timeout: 8))
        let map = app.buttons["View Map & Directions"]; scrollTo(map); map.tap()
        XCTAssertTrue(app.buttons["Start Navigation"].waitForExistence(timeout: 5)); capture("06-Map")
    }
    func testNoMatchCanBeRelaxedExplicitly() {
        start(); app.buttons["tab-surprise"].tap(); app.buttons["Offline ideas"].tap()
        app.buttons["mood-chill"].tap(); app.buttons["mood-adventure"].tap()
        scrollTo(app.buttons["Rs. 500"], bottomInset: 120); app.buttons["Rs. 500"].tap()
        let duration = app.buttons["1 hour"]; scrollTo(duration); duration.tap()
        let city = app.buttons["fallbackCity"]; scrollTo(city, bottomInset: 120); city.tap()
        let colombo = app.buttons["Colombo"]; XCTAssertTrue(colombo.waitForExistence(timeout: 5)); colombo.tap()
        app.buttons["findAdventure"].tap()
        XCTAssertTrue(app.staticTexts["Let’s make a little more room"].waitForExistence(timeout: 5)); capture("Planner-no-match")
        app.buttons["Open up my options"].tap(); app.buttons["findAdventure"].tap()
        XCTAssertTrue(app.buttons["markVisited"].waitForExistence(timeout: 8))
    }
    func testSearchEmptyStateAndCategoryFilter() {
        start(); app.buttons["tab-explore"].tap()
        app.buttons["Waterfalls"].tap(); XCTAssertTrue(app.staticTexts["4 places to make your day"].waitForExistence(timeout: 5)); capture("08-Explore-waterfalls")
        let search = app.textFields["placeSearch"]; search.tap(); search.typeText("not-a-place\n")
        XCTAssertTrue(app.staticTexts["Still a little undiscovered"].waitForExistence(timeout: 5)); capture("Explore-empty")
    }
    func testOnlineTripBudgetUnknownCostsAndSavedPlace() {
        app.terminate(); app.launchArguments = ["--uitesting", "--discovery-fixtures"]; app.launch()
        start(); app.buttons["tab-surprise"].tap()
        capture("Online-photo-planner")
        let city = app.buttons["onlineStartingCity"]; scrollTo(city, bottomInset: 120); city.tap()
        XCTAssertTrue(app.buttons["Colombo"].waitForExistence(timeout: 5)); app.buttons["Colombo"].tap()
        capture("Online-photo-location")
        app.buttons["findOnlinePlaces"].tap()
        let counts = app.staticTexts["onlineResultCounts"]
        XCTAssertTrue(counts.waitForExistence(timeout: 8))
        let edit = app.buttons["edit-plan-fixture-park"]; scrollTo(edit, bottomInset: 120)
        XCTAssertTrue(edit.waitForExistence(timeout: 5))
        XCTAssertFalse(app.buttons["onlineSurprise"].exists, "Unknown prices cannot qualify for a budget match")
        capture("Online-unknown-costs"); edit.tap()
        XCTAssertTrue(app.buttons["entryZero"].waitForExistence(timeout: 5)); scrollTo(app.buttons["entryZero"], bottomInset: 40); app.buttons["entryZero"].tap()
        scrollTo(app.buttons["savePlaceEstimate"], bottomInset: 40); app.buttons["savePlaceEstimate"].tap()
        XCTAssertTrue(app.buttons["onlineSurprise"].waitForExistence(timeout: 8))
        capture("Online-budget-fit")
        app.buttons["onlineSurprise"].tap()
        XCTAssertTrue(app.buttons["favorite-fixture-park"].waitForExistence(timeout: 5)); app.buttons["favorite-fixture-park"].tap()
        app.buttons["Back"].firstMatch.tap(); app.navigationBars.buttons["Back"].firstMatch.tap()
        app.buttons["tab-saved"].tap()
        XCTAssertTrue(app.staticTexts["Fixture Park"].waitForExistence(timeout: 5))
        app.staticTexts["Fixture Park"].tap()
        XCTAssertTrue(app.buttons["View Map & Directions"].waitForExistence(timeout: 5))
    }
    func testOnlineFindingMatchesOfflineDesignAndCanCancel() {
        app.terminate(); app.launchArguments = ["--uitesting", "--discovery-fixtures", "--slow-discovery-fixture"]; app.launch()
        start(); app.buttons["tab-surprise"].tap(); app.buttons["findOnlinePlaces"].tap()
        XCTAssertTrue(app.staticTexts["onlineFinding"].waitForExistence(timeout: 4))
        capture("Online-photo-finding", settle: 0.05)
        app.buttons["Cancel search"].tap()
        XCTAssertTrue(app.staticTexts["Plan Your Adventure"].waitForExistence(timeout: 5))
        XCTAssertFalse(app.staticTexts["onlineResultCounts"].exists)
    }
    func testPersonalFeelingChoicesAreRememberedAndOfflineTempleMatchWorks() {
        start(); app.buttons["tab-surprise"].tap(); app.buttons["Offline ideas"].tap()
        let sad = app.buttons["feeling-sad"]; scrollTo(sad, bottomInset: 130); sad.tap()
        let temple = app.buttons["experience-temple"]; scrollTo(temple, bottomInset: 130); temple.tap()
        XCTAssertTrue(temple.isSelected); capture("Personal-feeling-temple")
        scrollTo(sad, bottomInset: 130); capture("Personal-feeling-faces")
        let happy = app.buttons["feeling-happy"]; scrollTo(happy, bottomInset: 130); happy.tap()
        scrollTo(temple, bottomInset: 130); XCTAssertFalse(temple.isSelected)
        let sea = app.buttons["experience-seaside"]; scrollTo(sea, bottomInset: 130); sea.tap()
        scrollTo(sad, bottomInset: 130); sad.tap()
        scrollTo(temple, bottomInset: 130); XCTAssertTrue(temple.isSelected); XCTAssertFalse(sea.isSelected)
        let skip = app.buttons["skipFeeling"]; scrollTo(skip, bottomInset: 130); skip.tap()
        XCTAssertFalse(app.buttons["experience-temple"].exists)
        scrollTo(sad, bottomInset: 130); sad.tap()
        scrollTo(temple, bottomInset: 130); XCTAssertTrue(temple.isSelected)
        app.buttons["findAdventure"].tap()
        XCTAssertTrue(app.buttons["markVisited"].waitForExistence(timeout: 8))
        XCTAssertTrue(app.staticTexts["Gangaramaya Temple"].exists || app.staticTexts["Temple of the Sacred Tooth Relic"].exists)
        let reason = app.descendants(matching: .any).matching(identifier: "personalizedMatchReason").firstMatch; scrollTo(reason, bottomInset: 120)
        XCTAssertTrue(reason.exists); capture("Personal-feeling-offline-match")
    }
    func testOnlinePersonalPreferenceFiltersResultsAndKeepsUnknownCosts() {
        app.terminate(); app.launchArguments = ["--uitesting", "--discovery-fixtures"]; app.launch()
        start(); app.buttons["tab-surprise"].tap()
        let sad = app.buttons["feeling-sad"]; scrollTo(sad, bottomInset: 130); sad.tap()
        let temple = app.buttons["experience-temple"]; scrollTo(temple, bottomInset: 130); temple.tap()
        app.buttons["findOnlinePlaces"].tap()
        XCTAssertTrue(app.staticTexts["onlineResultCounts"].waitForExistence(timeout: 8))
        XCTAssertTrue(app.staticTexts["Fixture Temple"].exists)
        XCTAssertFalse(app.staticTexts["Fixture Park"].exists); XCTAssertFalse(app.staticTexts["Fixture Beach"].exists)
        XCTAssertFalse(app.buttons["onlineSurprise"].exists)
        let edit = app.buttons["edit-plan-fixture-temple"]; scrollTo(edit, bottomInset: 140); edit.tap()
        let zero = app.buttons["entryZero"]; scrollTo(zero, bottomInset: 50); zero.tap()
        let save = app.buttons["savePlaceEstimate"]; scrollTo(save); save.tap()
        XCTAssertTrue(app.buttons["onlineSurprise"].waitForExistence(timeout: 8)); capture("Personal-feeling-online-match")
        app.buttons["onlineSurprise"].tap()
        XCTAssertTrue(app.staticTexts["Fixture Temple"].waitForExistence(timeout: 5))
    }
    func testLiveColomboOnlineSearchWhenRequested() throws {
        guard ProcessInfo.processInfo.environment["ADO_LIVE_DISCOVERY"] == "1" else { throw XCTSkip("Opt-in live network test; set TEST_RUNNER_ADO_LIVE_DISCOVERY=1.") }
        app.terminate(); app.launchArguments = ["--uitesting"]; app.launch(); start()
        app.buttons["tab-surprise"].tap()
        let city = app.buttons["onlineStartingCity"]; scrollTo(city, bottomInset: 120); city.tap()
        XCTAssertTrue(app.buttons["Colombo"].waitForExistence(timeout: 5)); app.buttons["Colombo"].tap()
        app.buttons["findOnlinePlaces"].tap()
        let result = app.staticTexts["onlineResultCounts"]
        XCTAssertTrue(result.waitForExistence(timeout: 60))
        XCTAssertTrue(app.staticTexts["Apple Maps"].firstMatch.exists || app.staticTexts["Wikipedia"].firstMatch.exists)
        app.swipeUp()
        let photograph = app.otherElements.matching(NSPredicate(format: "identifier BEGINSWITH %@", "loaded-photo-")).firstMatch
        XCTAssertTrue(photograph.waitForExistence(timeout: 25), "The live discovery should render a real downloaded landmark photograph")
        capture("Live-Colombo-discovery")
    }

}
