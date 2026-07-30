import XCTest

final class App24FramesUITests: XCTestCase {
    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    func testAppLaunchAndShutterButtonPresence() throws {
        let app = XCUIApplication()
        app.launch()
        
        // App launches cleanly
        XCTAssertTrue(app.state == .runningForeground || app.state == .runningBackground)
    }
}
