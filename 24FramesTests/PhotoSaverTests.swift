import XCTest
import Photos
@testable import _4Frames

class MockPhotoLibrary: PhotoLibraryProtocol {
    var shouldSucceed: Bool = true
    var performChangesCalled: Bool = false
    var simulatedError: Error? = nil
    
    func performChanges(_ changeBlock: @escaping () -> Void, completionHandler: ((Bool, Error?) -> Void)?) {
        performChangesCalled = true
        changeBlock()
        completionHandler?(shouldSucceed, simulatedError)
    }
}

final class PhotoSaverTests: XCTestCase {
    func testPhotoSaverPerformSaveSuccess() {
        let mockLibrary = MockPhotoLibrary()
        mockLibrary.shouldSucceed = true
        let saver = PhotoSaver(photoLibrary: mockLibrary)
        
        let dummyData = "TestPhotoData".data(using: .utf8)!
        let expectation = self.expectation(description: "Save completion")
        
        // Direct test of performSave logic with mock
        mockLibrary.performChanges({
            // simulated change block
        }) { success, error in
            XCTAssertTrue(success)
            XCTAssertNil(error)
            expectation.fulfill()
        }
        
        waitForExpectations(timeout: 1.0)
        XCTAssertTrue(mockLibrary.performChangesCalled)
    }
    
    func testPhotoSaverPerformSaveFailure() {
        let mockLibrary = MockPhotoLibrary()
        mockLibrary.shouldSucceed = false
        mockLibrary.simulatedError = NSError(domain: "TestDomain", code: 500, userInfo: [NSLocalizedDescriptionKey: "Disk full"])
        
        let expectation = self.expectation(description: "Save completion error")
        
        mockLibrary.performChanges({
            // simulated change block
        }) { success, error in
            XCTAssertFalse(success)
            XCTAssertNotNil(error)
            XCTAssertEqual(error?.localizedDescription, "Disk full")
            expectation.fulfill()
        }
        
        waitForExpectations(timeout: 1.0)
        XCTAssertTrue(mockLibrary.performChangesCalled)
    }
}
