import SwiftUI

public struct ContentView: View {
    @StateObject private var cameraManager = CameraManager()
    @State private var isShutterRingAnimating = false
    @State private var isShowingPhotoLibrary = false
    
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
                        
                        if let capturedImage = cameraManager.latestCapturedImage {
                            FlyToCornerAnimationView(image: capturedImage) {
                                cameraManager.latestCapturedImage = nil
                            }
                        }
                    }
                    
                    Spacer(minLength: 0)
                    
                    // Bottom Controls Bar
                    ZStack {
                        ShutterRingView(isAnimating: $isShutterRingAnimating)
                        
                        HStack {
                            Spacer()
                            
                            ShutterButtonView {
                                triggerShutter()
                            }
                            
                            Spacer()
                        }
                        
                        HStack {
                            RecentPhotoThumbnailView(image: cameraManager.lastSavedThumbnail) {
                                HapticManager.selection()
                                isShowingPhotoLibrary = true
                            }
                            .padding(.leading, 28)
                            
                            Spacer()
                            
                            CameraFlipButtonView {
                                cameraManager.toggleCamera()
                            }
                            .padding(.trailing, 28)
                        }
                    }
                    .frame(height: 100)
                    .padding(.bottom, 52)
                }
            case .denied:
                PermissionDeniedView()
            case .notDetermined:
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
            }
        }
        .sheet(isPresented: $isShowingPhotoLibrary) {
            PhotoLibraryPickerView()
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
