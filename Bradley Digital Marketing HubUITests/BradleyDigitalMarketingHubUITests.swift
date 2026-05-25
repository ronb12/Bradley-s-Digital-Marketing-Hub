import XCTest

final class BradleyDigitalMarketingHubUITests: XCTestCase {
    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    func testWelcomeScreenShowsDemoModeEntry() throws {
        let app = XCUIApplication()
        app.launch()

        XCTAssertTrue(app.otherElements["welcome_screen"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["welcome_demo_mode_button"].exists)
    }

    func testDemoModeOpensMainTabs() throws {
        let app = XCUIApplication()
        app.launch()

        app.buttons["welcome_demo_mode_button"].tap()
        XCTAssertTrue(app.tabBars.buttons["Home"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.tabBars.buttons["Tools"].exists)
    }
}
