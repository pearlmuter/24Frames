import SwiftUI

public struct ContentView: View {
    @StateObject private var cameraManager = CameraManager()
    @StateObject private var volumeObserver = VolumeButtonObserver()
    @StateObject private var settings = AppSettings.shared
    @StateObject private var filmManager = FilmDevelopManager.shared
    
    @State private var isShutterRingAnimating = false
    @State private var isShowingPhotoLibrary = false
    @State private var isShowingDevelopAlert = false
    @State private var developAlertMessage = ""
    
    public init() {}
    
    public var body: some View {
        GeometryReader { geometry in
            let screenWidth = geometry.size.width
            let previewHeight = screenWidth * (4.0 / 3.0)
            
            ZStack {
                Color.black.edgesIgnoringSafeArea(.all)
                
                // Hidden volume view to suppress system volume slider HUD
                VolumeViewHidden()
                    .frame(width: 0, height: 0)
                    .opacity(0)
                
                switch cameraManager.permissionState {
                case .authorized:
                    VStack(spacing: 0) {
                        // Top Header Bar with Countdown & Optional Film Roll Icon
                        HStack {
                            Spacer()
                            
                            Text(settings.isInfinitePicturesMode ? "∞" : "\(settings.remainingPhotosToday)")
                                .font(.system(size: 48, weight: .black, design: .monospaced))
                                .foregroundColor(.white)
                            
                            Spacer()
                        }
                        .overlay(
                            HStack {
                                Spacer()
                                if settings.isDevelopModeEnabled {
                                    FilmRollButtonView(rollCount: filmManager.activeRollPhotoCount) {
                                        HapticManager.medium()
                                        let count = filmManager.activeRollPhotoCount
                                        developAlertMessage = "Are you sure? You took \(count) pictures. You can only get one roll of pictures for today."
                                        isShowingDevelopAlert = true
                                    }
                                    .padding(.trailing, 20)
                                }
                            }
                        )
                        .padding(.top, 8)
                        .padding(.bottom, 6)
                        
                        // 4:3 Aspect Ratio Camera View Finder (Strict 375x500 on iPhone 13 mini, Edge-to-Edge)
                        ZStack {
                            CameraPreview(cameraManager: cameraManager)
                                .grayscale(settings.isBlackAndWhiteMode ? 1.0 : 0.0)
                                .frame(width: screenWidth, height: previewHeight)
                                .clipped()
                            
                            if let capturedImage = cameraManager.latestCapturedImage {
                                FlyToCornerAnimationView(image: capturedImage) {
                                    cameraManager.latestCapturedImage = nil
                                }
                                .frame(width: screenWidth, height: previewHeight)
                            }
                        }
                        
                        Spacer(minLength: 0)
                        
                        // Bottom Controls Bar (Positioned at the very bottom of the screen)
                        ZStack {
                            ShutterRingView(isAnimating: $isShutterRingAnimating)
                            
                            HStack {
                                Spacer()
                                
                                ShutterButtonView {
                                    triggerShutter()
                                }
                                .disabled(!settings.canTakePhoto)
                                .opacity(settings.canTakePhoto ? 1.0 : 0.4)
                                
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
                        .padding(.bottom, 16)
                    }
                case .denied:
                    PermissionDeniedView()
                case .notDetermined:
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                }
            }
        }
        .sheet(isPresented: $isShowingPhotoLibrary) {
            PhotoLibraryPickerView()
        }
        .alert(isPresented: $isShowingDevelopAlert) {
            Alert(
                title: Text("Send Roll to Develop?"),
                message: Text(developAlertMessage),
                primaryButton: .default(Text("OK")) {
                    filmManager.sendRollToDevelop(speed: settings.developmentSpeed, photoSaver: PhotoSaver()) { count in
                        if settings.isInfinitePicturesMode {
                            settings.resetPhotoCountForNewRoll()
                        } else {
                            settings.hasSubmittedRollToday = true
                        }
                    }
                },
                secondaryButton: .cancel(Text("Cancel"))
            )
        }
        .onAppear {
            cameraManager.onPhotoCaptured = {
                triggerRingAnimation()
            }
            volumeObserver.onVolumeButtonTap = {
                triggerShutter()
            }
            volumeObserver.startListening()
            filmManager.checkAndProcessScheduledDevelopments(photoSaver: PhotoSaver())
        }
        .onDisappear {
            volumeObserver.stopListening()
        }
        .onOpenURL { url in
            if url.host == "snap" || url.absoluteString.contains("snap") {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    triggerShutter()
                }
            }
        }
    }
    
    private func triggerShutter() {
        guard settings.canTakePhoto else { return }
        cameraManager.capturePhoto()
    }
    
    private func triggerRingAnimation() {
        withAnimation(.easeOut(duration: 0.4)) {
            isShutterRingAnimating = true
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
            isShutterRingAnimating = false
        }
    }
}
