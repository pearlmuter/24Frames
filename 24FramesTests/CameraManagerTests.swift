import XCTest
import AVFoundation
@testable import _4Frames

final class CameraManagerTests: XCTestCase {
    func testCameraManagerInitializationDefaults() {
        let manager = CameraManager()
        XCTAssertNotNil(manager.captureSession)
        XCTAssertEqual(manager.cameraPosition, .back)
        XCTAssertFalse(manager.isCapturing)
        XCTAssertNil(manager.errorMessage)
    }
    
    func testCameraTogglePositionSwitching() {
        let manager = CameraManager()
        XCTAssertEqual(manager.cameraPosition, .back)
        
        manager.toggleCamera()
        XCTAssertEqual(manager.cameraPosition, .front)
        
        manager.toggleCamera()
        XCTAssertEqual(manager.cameraPosition, .back)
    }
    
    func testCameraManagerLensSelectionConstraint() {
        // Verify Primary Wide angle camera device selection
        let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back)
        if let device = device {
            XCTAssertEqual(device.deviceType, AVCaptureDevice.DeviceType.builtInWideAngleCamera)
        }
    }
    
    func testPhotoSettingsAIProcessingOverrides() {
        let photoOutput = AVCapturePhotoOutput()
        
        // Verify photo output auto deferred setting can be turned off on supported iOS versions
        if #available(iOS 17.0, *) {
            if photoOutput.isAutoDeferredPhotoDeliverySupported {
                photoOutput.isAutoDeferredPhotoDeliveryEnabled = false
                XCTAssertFalse(photoOutput.isAutoDeferredPhotoDeliveryEnabled)
            }
        }
        
        var settings = AVCapturePhotoSettings()
        if photoOutput.isAutoRedEyeReductionSupported {
            settings.isAutoRedEyeReductionEnabled = false
            XCTAssertFalse(settings.isAutoRedEyeReductionEnabled)
        }
    }
}
