import Foundation
import AVFoundation
import SwiftUI
import Combine

public enum CameraPermissionState {
    case notDetermined
    case authorized
    case denied
}

public class CameraManager: NSObject, ObservableObject {
    @Published public var permissionState: CameraPermissionState = .notDetermined
    @Published public var isSessionRunning: Bool = false
    @Published public var isCapturing: Bool = false
    @Published public var cameraPosition: AVCaptureDevice.Position = .back
    @Published public var lastCapturedPhotoData: Data? = nil
    @Published public var latestCapturedImage: UIImage? = nil
    @Published public var lastSavedThumbnail: UIImage? = nil
    @Published public var errorMessage: String? = nil
    
    public let captureSession = AVCaptureSession()
    private let photoOutput = AVCapturePhotoOutput()
    private var videoDeviceInput: AVCaptureDeviceInput?
    private let sessionQueue = DispatchQueue(label: "com.24frames.cameraSessionQueue")
    private let photoSaver: PhotoSaver
    
    public var onPhotoCaptured: (() -> Void)?
    
    public init(photoSaver: PhotoSaver = PhotoSaver()) {
        self.photoSaver = photoSaver
        super.init()
        checkPermissions()
    }
    
    public func checkPermissions() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            DispatchQueue.main.async {
                self.permissionState = .authorized
            }
            configureSession()
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { [weak self] granted in
                DispatchQueue.main.async {
                    self?.permissionState = granted ? .authorized : .denied
                }
                if granted {
                    self?.configureSession()
                }
            }
        case .denied, .restricted:
            DispatchQueue.main.async {
                self.permissionState = .denied
            }
        @unknown default:
            DispatchQueue.main.async {
                self.permissionState = .denied
            }
        }
    }
    
    public func configureSession() {
        sessionQueue.async { [weak self] in
            guard let self = self else { return }
            self.captureSession.beginConfiguration()
            self.captureSession.sessionPreset = .photo
            
            // Remove existing input if any
            if let currentInput = self.videoDeviceInput {
                self.captureSession.removeInput(currentInput)
            }
            
            // Strictly lock lens to Primary Wide (.builtInWideAngleCamera) for specified position
            guard let videoDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: self.cameraPosition) else {
                DispatchQueue.main.async {
                    self.errorMessage = "Primary Wide camera is unavailable for position: \(self.cameraPosition.rawValue)."
                }
                self.captureSession.commitConfiguration()
                return
            }
            
            do {
                let videoInput = try AVCaptureDeviceInput(device: videoDevice)
                if self.captureSession.canAddInput(videoInput) {
                    self.captureSession.addInput(videoInput)
                    self.videoDeviceInput = videoInput
                }
            } catch {
                DispatchQueue.main.async {
                    self.errorMessage = "Unable to create video input: \(error.localizedDescription)"
                }
                self.captureSession.commitConfiguration()
                return
            }
            
            if self.captureSession.canAddOutput(self.photoOutput) {
                self.captureSession.addOutput(self.photoOutput)
                
                // Disable auto deferred photo delivery if supported on hardware (iOS 17+)
                if #available(iOS 17.0, *) {
                    if self.photoOutput.isAutoDeferredPhotoDeliverySupported {
                        self.photoOutput.isAutoDeferredPhotoDeliveryEnabled = false
                    }
                }
            }
            
            self.captureSession.commitConfiguration()
            self.startSession()
        }
    }
    
    public func toggleCamera() {
        HapticManager.impact(style: .light)
        cameraPosition = (cameraPosition == .back) ? .front : .back
        configureSession()
    }
    
    public func startSession() {
        sessionQueue.async { [weak self] in
            guard let self = self, !self.captureSession.isRunning else { return }
            self.captureSession.startRunning()
            DispatchQueue.main.async {
                self.isSessionRunning = self.captureSession.isRunning
            }
        }
    }
    
    public func stopSession() {
        sessionQueue.async { [weak self] in
            guard let self = self, self.captureSession.isRunning else { return }
            self.captureSession.stopRunning()
            DispatchQueue.main.async {
                self.isSessionRunning = self.captureSession.isRunning
            }
        }
    }
    
    public func capturePhoto() {
        HapticManager.impact(style: .medium)
        sessionQueue.async { [weak self] in
            guard let self = self else { return }
            
            // Build photo settings specifying HEIC format where supported
            var photoSettings = AVCapturePhotoSettings()
            if self.photoOutput.availablePhotoCodecTypes.contains(.hevc) {
                photoSettings = AVCapturePhotoSettings(format: [AVVideoCodecKey: AVVideoCodecType.hevc])
            }
            
            // Explicitly disable AI computational options to guarantee Base Capture
            if self.photoOutput.isAutoRedEyeReductionSupported {
                photoSettings.isAutoRedEyeReductionEnabled = false
            }
            
            // Dynamic landscape / portrait video orientation handling and un-mirrored photo output
            if let connection = self.photoOutput.connection(with: .video) {
                if connection.isVideoOrientationSupported {
                    let deviceOrientation = UIDevice.current.orientation
                    let videoOrientation: AVCaptureVideoOrientation
                    switch deviceOrientation {
                    case .portrait:
                        videoOrientation = .portrait
                    case .portraitUpsideDown:
                        videoOrientation = .portraitUpsideDown
                    case .landscapeLeft:
                        videoOrientation = .landscapeRight
                    case .landscapeRight:
                        videoOrientation = .landscapeLeft
                    default:
                        videoOrientation = .portrait
                    }
                    connection.videoOrientation = videoOrientation
                }
                
                if connection.isVideoMirroringSupported {
                    connection.automaticallyAdjustsVideoMirroring = false
                    connection.isVideoMirrored = false
                }
            }
            
            DispatchQueue.main.async {
                self.isCapturing = true
                self.onPhotoCaptured?()
            }
            
            self.photoOutput.capturePhoto(with: photoSettings, delegate: self)
        }
    }
    
    public func setFocusAndExposure(at point: CGPoint, in viewBounds: CGSize) {
        sessionQueue.async { [weak self] in
            guard let device = self?.videoDeviceInput?.device else { return }
            
            // Translate view point to normalized camera point (0,0 top-left to 1,1 bottom-right)
            let normalizedPoint = CGPoint(
                x: point.y / viewBounds.height,
                y: 1.0 - (point.x / viewBounds.width)
            )
            
            do {
                try device.lockForConfiguration()
                
                if device.isFocusPointOfInterestSupported && device.isFocusModeSupported(.autoFocus) {
                    device.focusPointOfInterest = normalizedPoint
                    device.focusMode = .autoFocus
                }
                
                if device.isExposurePointOfInterestSupported && device.isExposureModeSupported(.autoExpose) {
                    device.exposurePointOfInterest = normalizedPoint
                    device.exposureMode = .autoExpose
                }
                
                device.isSubjectAreaChangeMonitoringEnabled = true
                device.unlockForConfiguration()
            } catch {
                DispatchQueue.main.async {
                    self?.errorMessage = "Failed to lock device for focus/exposure configuration."
                }
            }
        }
    }
}

extension CameraManager: AVCapturePhotoCaptureDelegate {
    public func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        DispatchQueue.main.async {
            self.isCapturing = false
        }
        
        if let error = error {
            DispatchQueue.main.async {
                self.errorMessage = "Photo capture error: \(error.localizedDescription)"
            }
            return
        }
        
        guard let fileData = photo.fileDataRepresentation() else {
            DispatchQueue.main.async {
                self.errorMessage = "Failed to obtain photo file data representation."
            }
            return
        }
        
        DispatchQueue.main.async {
            self.lastCapturedPhotoData = fileData
            if let image = UIImage(data: fileData) {
                self.latestCapturedImage = image
                self.lastSavedThumbnail = image
            }
        }
        
        photoSaver.savePhotoData(fileData) { [weak self] result in
            DispatchQueue.main.async {
                switch result {
                case .success:
                    break
                case .failure(let error):
                    self?.errorMessage = "Failed to save photo: \(error)"
                }
            }
        }
    }
}
