import XCTest
@testable import _4Frames

final class AppSettingsTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        let settings = AppSettings.shared
        settings.isInfinitePicturesMode = false
        settings.isBlackAndWhiteMode = false
        settings.isDevelopModeEnabled = false
        settings.photosTakenToday = 0
        settings.developmentSpeed = .immediate
        settings.checkDailyReset()
    }
    
    func testAppSettingsDefaults() {
        let settings = AppSettings.shared
        XCTAssertFalse(settings.isInfinitePicturesMode)
        XCTAssertFalse(settings.isBlackAndWhiteMode)
        XCTAssertFalse(settings.isDevelopModeEnabled)
        XCTAssertEqual(settings.photosTakenToday, 0)
        XCTAssertEqual(settings.remainingPhotosToday, 24)
        XCTAssertTrue(settings.canTakePhoto)
    }
    
    func testPhotoCountIncrementation() {
        let settings = AppSettings.shared
        settings.incrementPhotoCount()
        XCTAssertEqual(settings.photosTakenToday, 1)
        XCTAssertEqual(settings.remainingPhotosToday, 23)
        XCTAssertTrue(settings.canTakePhoto)
    }
    
    func testDailyLimitEnforcement() {
        let settings = AppSettings.shared
        settings.photosTakenToday = 24
        XCTAssertEqual(settings.remainingPhotosToday, 0)
        XCTAssertFalse(settings.canTakePhoto)
    }
    
    func testInfiniteModeBypassesLimit() {
        let settings = AppSettings.shared
        settings.photosTakenToday = 24
        settings.isInfinitePicturesMode = true
        XCTAssertTrue(settings.canTakePhoto)
        XCTAssertEqual(settings.remainingPhotosToday, 24)
    }
    
    func testInfiniteOffAtRollBoundaryShowsZero() {
        // User took exactly 24 photos, infinite was on (showing 24),
        // then turned infinite off → should show 0 (roll is spent)
        let settings = AppSettings.shared
        settings.photosTakenToday = 24
        settings.isInfinitePicturesMode = false
        XCTAssertEqual(settings.remainingPhotosToday, 0)
        XCTAssertFalse(settings.canTakePhoto)
    }
    
    func testInfiniteOffMidRollPreservesRemaining() {
        // User took 30 photos (infinite was on), turned infinite off →
        // should show 18 remaining in current roll (24 - 6)
        let settings = AppSettings.shared
        settings.photosTakenToday = 30
        settings.isInfinitePicturesMode = false
        XCTAssertEqual(settings.remainingPhotosToday, 18)
        XCTAssertTrue(settings.canTakePhoto)
    }
    
    func testSubmitRollForDevelopmentInStandardModeSetsCountToZero() {
        let settings = AppSettings.shared
        settings.isDevelopModeEnabled = true
        settings.isInfinitePicturesMode = false
        settings.photosTakenToday = 10
        
        settings.submitRollForDevelopment()
        
        XCTAssertEqual(settings.remainingPhotosToday, 0)
        XCTAssertFalse(settings.canTakePhoto)
    }
    
    func testSubmitRollForDevelopmentInInfiniteModeResetsCountToTwentyFour() {
        let settings = AppSettings.shared
        settings.isDevelopModeEnabled = true
        settings.isInfinitePicturesMode = true
        settings.photosTakenToday = 10
        
        settings.submitRollForDevelopment()
        
        XCTAssertEqual(settings.remainingPhotosToday, 24)
        XCTAssertTrue(settings.canTakePhoto)
    }
}
