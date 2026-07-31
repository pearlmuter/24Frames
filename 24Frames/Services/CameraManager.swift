import Foundation
import AVFoundation
import SwiftUI
import Combine
import CoreImage

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
    private let ciContext = CIContext(options: nil)
    
    public var onPhotoCaptured: (() -> Void)?
    
    public init(photoSaver: PhotoSaver = PhotoSaver()) {
        self.photoSaver = photoSaver
        super.init()
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            self?.checkPermissions()
        }
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
            
            // Lock lens to Primary Wide (.builtInWideAngleCamera)
            if let currentInput = self.videoDeviceInput {
                self.captureSession.removeInput(currentInput)
            }
            
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
                } else {
                    DispatchQueue.main.async {
                        self.errorMessage = "Cannot add Primary Wide camera input."
                    }
                    self.captureSession.commitConfiguration()
                    return
                }
            } catch {
                DispatchQueue.main.async {
                    self.errorMessage = "Failed to create video device input: \(error.localizedDescription)"
                }
                self.captureSession.commitConfiguration()
                return
            }
            
            if !self.captureSession.outputs.contains(self.photoOutput) {
                if self.captureSession.canAddOutput(self.photoOutput) {
                    self.captureSession.addOutput(self.photoOutput)
                    self.photoOutput.isHighResolutionCaptureEnabled = true
                    self.photoOutput.maxPhotoQualityPrioritization = .speed
                } else {
                    DispatchQueue.main.async {
                        self.errorMessage = "Cannot add photo output to capture session."
                    }
                    self.captureSession.commitConfiguration()
                    return
                }
            }
            
            self.captureSession.commitConfiguration()
            self.startSession()
        }
    }
    
    public func toggleCamera() {
        cameraPosition = (cameraPosition == .back) ? .front : .back
        configureSession()
    }
    
    public func startSession() {
        sessionQueue.async { [weak self] in
            guard let self = self else { return }
            if !self.captureSession.isRunning {
                self.captureSession.startRunning()
                DispatchQueue.main.async {
                    self.isSessionRunning = self.captureSession.isRunning
                }
            }
        }
    }
    
    public func stopSession() {
        sessionQueue.async { [weak self] in
            guard let self = self else { return }
            if self.captureSession.isRunning {
                self.captureSession.stopRunning()
                DispatchQueue.main.async {
                    self.isSessionRunning = self.captureSession.isRunning
                }
            }
        }
    }
    
    public func capturePhoto() {
        guard AppSettings.shared.canTakePhoto else {
            DispatchQueue.main.async {
                self.errorMessage = "Daily photo limit reached (24 photos max per day)."
            }
            return
        }
        
        sessionQueue.async { [weak self] in
            guard let self = self else { return }
            
            var photoSettings: AVCapturePhotoSettings
            if self.photoOutput.availablePhotoCodecTypes.contains(.hevc) {
                photoSettings = AVCapturePhotoSettings(format: [AVVideoCodecKey: AVVideoCodecType.hevc])
            } else {
                photoSettings = AVCapturePhotoSettings()
            }
            
            photoSettings.photoQualityPrioritization = .speed
            photoSettings.isHighResolutionPhotoEnabled = true
            
            if let connection = self.photoOutput.connection(with: .video) {
                if connection.isVideoOrientationSupported {
                    let currentOrientation = UIDevice.current.orientation
                    let videoOrientation: AVCaptureVideoOrientation
                    switch currentOrientation {
                    case .landscapeLeft:
                        videoOrientation = .landscapeRight
                    case .landscapeRight:
                        videoOrientation = .landscapeLeft
                    case .portraitUpsideDown:
                        videoOrientation = .portraitUpsideDown
                    default:
                        videoOrientation = .portrait
                    }
                    connection.videoOrientation = videoOrientation
                }
                
                if connection.isVideoMirroringSupported {
                    connection.automaticallyAdjustsVideoMirroring = false
                    connection.isVideoMirrored = (self.cameraPosition == .front)
                }
            }
            
            DispatchQueue.main.async {
                self.isCapturing = true
                AppSettings.shared.incrementPhotoCount()
                HapticManager.shutter()
            }
            
            self.photoOutput.capturePhoto(with: photoSettings, delegate: self)
        }
    }
    
    private func processImageData(_ rawData: Data) -> Data {
        guard AppSettings.shared.isBlackAndWhiteMode,
              let ciImage = CIImage(data: rawData) else {
            return rawData
        }
        
        let filter = CIFilter(name: "CIPhotoEffectMono")
        filter?.setValue(ciImage, forKey: kCIInputImageKey)
        
        guard let outputImage = filter?.outputImage else {
            return rawData
        }
        
        if let heifData = ciContext.heifRepresentation(of: outputImage, format: .RGBA8, colorSpace: CGColorSpaceCreateDeviceRGB()) {
            return heifData
        }
        
        if let cgImage = ciContext.createCGImage(outputImage, from: outputImage.extent) {
            let uiImage = UIImage(cgImage: cgImage, scale: 1.0, orientation: .up)
            if let bwData = uiImage.jpegData(compressionQuality: 0.98) {
                return bwData
            }
        }
        
        return rawData
    }
    
    public func setFocusAndExposure(at point: CGPoint, in viewSize: CGSize) {
        sessionQueue.async { [weak self] in
            guard let device = self?.videoDeviceInput?.device, viewSize.width > 0, viewSize.height > 0 else { return }
            let normalizedPoint = CGPoint(x: point.y / viewSize.height, y: 1.0 - (point.x / viewSize.width))
            
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
        
        guard let rawFileData = photo.fileDataRepresentation() else {
            DispatchQueue.main.async {
                self.errorMessage = "Failed to obtain photo file data representation."
            }
            return
        }
        
        let fileData = processImageData(rawFileData)
        
        DispatchQueue.main.async {
            self.lastCapturedPhotoData = fileData
            if let image = UIImage(data: fileData) {
                self.latestCapturedImage = image
                self.lastSavedThumbnail = image
                self.onPhotoCaptured?()
            }
        }
        
        if AppSettings.shared.isDevelopModeEnabled {
            FilmDevelopManager.shared.savePhotoToActiveRoll(data: fileData)
        } else {
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
}
