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
                VStack(spacing: 0) {
                    Spacer(minLength: 0)
                    
                    // 4:3 Aspect Ratio Camera View Finder with black letterboxing
                    ZStack {
                        CameraPreview(cameraManager: cameraManager)
                            .aspectRatio(3.0 / 4.0, contentMode: .fit)
                            .clipped()
                        
                        ShutterRingView(isAnimating: $isShutterRingAnimating)
                    }
                    
                    Spacer(minLength: 0)
                    
                    // Bottom Controls Bar
                    ZStack {
                        HStack {
                            Spacer()
                            
                            ShutterButtonView {
                                triggerShutter()
                            }
                            
                            Spacer()
                        }
                        
                        HStack {
                            Spacer()
                            
                            CameraFlipButtonView {
                                cameraManager.toggleCamera()
                            }
                            .padding(.trailing, 28)
                        }
                    }
                    .frame(height: 100)
                    .padding(.bottom, 24)
                }
                .edgesIgnoringSafeArea(.bottom)
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
