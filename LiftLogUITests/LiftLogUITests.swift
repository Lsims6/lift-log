import XCTest

/// Runs on a simulated iPhone in the GitHub build: logs a set on Monday's workout, closes the app,
/// reopens it, and checks the set is still there. It always uses Monday so it doesn't depend on
/// which day the build happens to run. Screenshots are kept for review.
final class LiftLogUITests: XCTestCase {
    override func setUp() {
        continueAfterFailure = false
    }

    private func shot(_ app: XCUIApplication, _ name: String) {
        let png = app.screenshot().pngRepresentation
        let attachment = XCTAttachment(data: png, uniformTypeIdentifier: "public.png")
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }

    /// The Mon button in the week strip (its label is like "Monday, Oct 12").
    private func mondayButton(_ web: XCUIElement) -> XCUIElement {
        web.buttons.matching(NSPredicate(format: "label BEGINSWITH 'Monday'")).firstMatch
    }

    /// Scrolls down until the element is on screen; returns whether it was found.
    private func scrollTo(_ element: XCUIElement, in app: XCUIApplication, maxSwipes: Int = 8) -> Bool {
        for _ in 0..<maxSwipes {
            if element.exists && element.isHittable { return true }
            app.swipeUp()
        }
        return element.exists && element.isHittable
    }

    func testLoggedSetSurvivesRelaunch() {
        let app = XCUIApplication()
        app.launchArguments = ["-resetData"]
        app.launch()

        let web = app.webViews.firstMatch
        XCTAssertTrue(web.waitForExistence(timeout: 30), "The app's page never appeared")

        // Go to Monday (legs), whose first exercise sits near the top of the screen.
        let monday = mondayButton(web)
        XCTAssertTrue(monday.waitForExistence(timeout: 30), "The week strip didn't load")
        monday.tap()

        let firstSet = web.buttons["Set 1 done"].firstMatch
        XCTAssertTrue(firstSet.waitForExistence(timeout: 15), "Monday's set rows weren't shown")
        shot(app, "1-monday")

        firstSet.tap()
        sleep(1)
        shot(app, "2-set-logged")

        // The set should now be in History.
        web.buttons["History"].tap()
        XCTAssertTrue(web.staticTexts["Hack squats"].waitForExistence(timeout: 10), "The logged set didn't show in History")
        shot(app, "3-history")

        // Close and reopen without resetting: the set must still be there.
        app.terminate()
        app.launchArguments = []
        app.launch()
        let reopened = app.webViews.firstMatch
        XCTAssertTrue(reopened.waitForExistence(timeout: 30), "The app's page didn't come back after reopening")
        let historyTab = reopened.buttons["History"]
        XCTAssertTrue(historyTab.waitForExistence(timeout: 30))
        historyTab.tap()
        XCTAssertTrue(reopened.staticTexts["Hack squats"].waitForExistence(timeout: 10),
                      "The logged set was lost after closing the app")
        shot(app, "4-history-after-reopen")

        // Finish and lock Monday.
        reopened.buttons["Today"].tap()
        let monday2 = mondayButton(reopened)
        XCTAssertTrue(monday2.waitForExistence(timeout: 10))
        monday2.tap()
        let finish = reopened.buttons["Finish workout & lock"]
        XCTAssertTrue(scrollTo(finish, in: app), "The Finish workout button wasn't there")
        finish.tap()
        XCTAssertTrue(reopened.buttons["Unlock to edit"].waitForExistence(timeout: 10), "Finishing the workout didn't lock it")
        sleep(1)
        shot(app, "5-finished")

        reopened.buttons["Progress"].tap()
        sleep(1)
        shot(app, "6-progress")
    }
}
