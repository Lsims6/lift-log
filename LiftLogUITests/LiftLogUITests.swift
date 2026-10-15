import XCTest

/// Runs on a simulated iPhone in the GitHub build: logs a set, closes the app, reopens it,
/// and checks the set is still there. Screenshots are kept for review.
final class LiftLogUITests: XCTestCase {
    override func setUp() {
        continueAfterFailure = false
    }

    private func shot(_ app: XCUIApplication, _ name: String) {
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }

    func testLoggedSetSurvivesRelaunch() {
        let app = XCUIApplication()
        app.launchArguments = ["-resetData"]
        app.launch()

        let web = app.webViews.firstMatch
        XCTAssertTrue(web.waitForExistence(timeout: 30), "The app's page never appeared")

        // Today's first exercise, first set.
        let firstSet = web.buttons["Set 1 done"].firstMatch
        XCTAssertTrue(firstSet.waitForExistence(timeout: 30), "No set rows were shown")
        shot(app, "1-today-empty")

        firstSet.tap()
        let finish = web.buttons["Finish workout & lock"]
        XCTAssertTrue(finish.waitForExistence(timeout: 10), "Logging a set didn't register")
        shot(app, "2-set-logged")

        // Close and reopen without resetting: the set must still be there.
        app.terminate()
        app.launchArguments = []
        app.launch()
        let reopened = app.webViews.firstMatch
        XCTAssertTrue(reopened.buttons["Finish workout & lock"].waitForExistence(timeout: 30),
                      "The logged set was lost after closing the app")
        shot(app, "3-after-relaunch")

        reopened.buttons["Finish workout & lock"].tap()
        XCTAssertTrue(reopened.buttons["Unlock to edit"].waitForExistence(timeout: 10), "Finishing the workout didn't lock it")
        shot(app, "4-finished")

        reopened.buttons["Progress"].tap()
        sleep(1)
        shot(app, "5-progress")

        reopened.buttons["History"].tap()
        sleep(1)
        shot(app, "6-history")
    }
}
