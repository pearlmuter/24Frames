import SwiftUI

struct LandscapeRotationModifier: ViewModifier {
    let angle: Double
    
    func body(content: Content) -> some View {
        content
            .rotationEffect(.degrees(angle))
            .animation(.easeInOut(duration: 0.25), value: angle)
    }
}

extension View {
    func landscapeRotation(_ angle: Double) -> some View {
        self.modifier(LandscapeRotationModifier(angle: angle))
    }
}

public struct ContentView: View {
    @StateObject private var cameraManager = CameraManager()
    @StateObject private var volumeObserver = VolumeButtonObserver()
    @StateObject private var orientationObserver = OrientationObserver()
    @ObservedObject private var settings = AppSettings.shared
    @ObservedObject private var filmManager = FilmDevelopManager.shared
    
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
                        // Top Header Bar with Countdown & Optional Mustard Yellow Infinity Symbol & Film Roll Icon
                        HStack {
                            Spacer()
                            
                            HStack(alignment: .firstTextBaseline, spacing: 6) {
                                Text("\(settings.remainingPhotosToday)")
                                    .font(.system(size: 48, weight: .black, design: .monospaced))
                                    .foregroundColor(.white)
                                
                                if settings.isInfinitePicturesMode {
                                    Text("∞")
                                        .font(.system(size: 32, weight: .bold))
                                        .foregroundColor(Color(red: 0.95, green: 0.75, blue: 0.1)) // Airport sign / Mustard yellow
                                }
                            }
                            .landscapeRotation(orientationObserver.rotationAngle)
                            
                            Spacer()
                        }
                        .overlay(
                            HStack {
                                Spacer()
                                if settings.isDevelopModeEnabled {
                                    FilmRollButtonView(
                                        rollCount: filmManager.activeRollPhotoCount,
                                        countdownString: filmManager.nextDevelopCountdownString
                                    ) {
                                        HapticManager.medium()
                                        let count = filmManager.activeRollPhotoCount
                                        developAlertMessage = "Are you sure? You took \(count) pictures. You can only get one roll of pictures for today."
                                        isShowingDevelopAlert = true
                                    }
                                    .landscapeRotation(orientationObserver.rotationAngle)
                                    .padding(.trailing, 20)
                                }
                            }
                        )
                        .padding(.top, 8)
                        .padding(.bottom, 6)
                        
                        // 4:3 Aspect Ratio Camera View Finder (Strict 375x500 on iPhone 13 mini)
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
                        
                        // Bottom Controls Bar (UI buttons rotate in-place 90° / -90° / 180° with zero lag)
                        ZStack {
                            ShutterRingView(isAnimating: $isShutterRingAnimating)
                                .landscapeRotation(orientationObserver.rotationAngle)
                            
                            HStack {
                                Spacer()
                                
                                ShutterButtonView {
                                    triggerShutter()
                                }
                                .disabled(!settings.canTakePhoto)
                                .opacity(settings.canTakePhoto ? 1.0 : 0.4)
                                .landscapeRotation(orientationObserver.rotationAngle)
                                
                                Spacer()
                            }
                            
                            HStack {
                                if !settings.isDevelopModeEnabled {
                                    RecentPhotoThumbnailView(image: cameraManager.lastSavedThumbnail) {
                                        HapticManager.selection()
                                        isShowingPhotoLibrary = true
                                    }
                                    .landscapeRotation(orientationObserver.rotationAngle)
                                    .padding(.leading, 28)
                                } else {
                                    Spacer()
                                        .frame(width: 48)
                                }
                                
                                Spacer()
                                
                                CameraFlipButtonView {
                                    cameraManager.toggleCamera()
                                }
                                .landscapeRotation(orientationObserver.rotationAngle)
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
