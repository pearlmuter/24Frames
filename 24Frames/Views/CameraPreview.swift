import SwiftUI
import AVFoundation

public struct CameraPreview: UIViewRepresentable {
    public class VideoPreviewView: UIView {
        public override class var layerClass: AnyClass {
            return AVCaptureVideoPreviewLayer.self
        }
        
        public var videoPreviewLayer: AVCaptureVideoPreviewLayer {
            return layer as! AVCaptureVideoPreviewLayer
        }
    }
    
    @ObservedObject public var cameraManager: CameraManager
    
    public init(cameraManager: CameraManager) {
        self.cameraManager = cameraManager
    }
    
    public func makeUIView(context: Context) -> VideoPreviewView {
        let view = VideoPreviewView()
        view.backgroundColor = .black
        view.videoPreviewLayer.session = cameraManager.captureSession
        view.videoPreviewLayer.videoGravity = .resizeAspectFill
        
        let tapGesture = UITapGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handleTap(_:)))
        view.addGestureRecognizer(tapGesture)
        
        return view
    }
    
    public func updateUIView(_ uiView: VideoPreviewView, context: Context) {
        uiView.videoPreviewLayer.session = cameraManager.captureSession
    }
    
    public func makeCoordinator() -> Coordinator {
        Coordinator(cameraManager: cameraManager)
    }
    
    public class Coordinator: NSObject {
        private let cameraManager: CameraManager
        
        public init(cameraManager: CameraManager) {
            self.cameraManager = cameraManager
        }
        
        @objc public func handleTap(_ gesture: UITapGestureRecognizer) {
            guard let view = gesture.view else { return }
            let point = gesture.location(in: view)
            cameraManager.setFocusAndExposure(at: point, in: view.bounds.size)
        }
    }
}
