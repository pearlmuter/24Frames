import SwiftUI

public struct ContentView: View {
    @StateObject private var cameraManager = CameraManager()
    @State private var isShutterRingAnimating = false
    
    public init() {}
    
    public var body: some View {
        ZStack {
            Color.black.edgesIgnoringSafeArea(.all)
            
            switch cameraManager.permissionState {
            case .authorized:
                ZStack {
                    CameraPreview(cameraManager: cameraManager)
                        .edgesIgnoringSafeArea(.all)
                    
                    ShutterRingView(isAnimating: $isShutterRingAnimating)
                        .edgesIgnoringSafeArea(.all)
                    
                    VStack {
                        Spacer()
                        
                        ShutterButtonView {
                            triggerShutter()
                        }
                        .padding(.bottom, 36)
                    }
                }
            case .denied:
                PermissionDeniedView()
            case .notDetermined:
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
            }
        }
        .onAppear {
            cameraManager.onPhotoCaptured = {
                triggerRingAnimation()
            }
        }
    }
    
    private func triggerShutter() {
        triggerRingAnimation()
        cameraManager.capturePhoto()
    }
    
    private func triggerRingAnimation() {
        isShutterRingAnimating = false
        DispatchQueue.main.async {
            isShutterRingAnimating = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                isShutterRingAnimating = false
            }
        }
    }
}
