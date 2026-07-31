import SwiftUI

public struct ContentView: View {
    @StateObject private var cameraManager = CameraManager()
    @StateObject private var volumeObserver = VolumeButtonObserver()
    @StateObject private var settings = AppSettings.shared
    @StateObject private var filmManager = FilmDevelopManager.shared
    
    @State private var isShutterRingAnimating = false
    @State private var isShowingPhotoLibrary = false
    @State private var isShowingSettings = false
    @State private var isShowingDevelopAlert = false
    @State private var developAlertMessage = ""
    
    public init() {}
    
    public var body: some View {
        ZStack {
            Color.black.edgesIgnoringSafeArea(.all)
            
            // Hidden volume view to suppress system volume slider HUD
            VolumeViewHidden()
                .frame(width: 0, height: 0)
                .opacity(0)
            
            switch cameraManager.permissionState {
            case .authorized:
                VStack(spacing: 0) {
                    // Header Bar with Countdown & Settings Gear
                    HStack {
                        Spacer()
                        
                        // Remaining photos countdown display
                        Text(settings.isInfinitePicturesMode ? "∞" : "\(settings.remainingPhotosToday)")
                            .font(.system(size: 44, weight: .black, design: .monospaced))
                            .foregroundColor(.white)
                        
                        Spacer()
                    }
                    .overlay(
                        HStack {
                            Spacer()
                            Button(action: {
                                HapticManager.selection()
                                isShowingSettings = true
                            }) {
                                Image(systemName: "gearshape.fill")
                                    .font(.system(size: 22, weight: .bold))
                                    .foregroundColor(.white)
                                    .padding(.trailing, 24)
                            }
                        }
                    )
                    .padding(.top, 12)
                    .padding(.bottom, 8)
                    
                    Spacer(minLength: 0)
                    
                    // 4:3 Aspect Ratio Camera View Finder with black letterboxing
                    ZStack {
                        CameraPreview(cameraManager: cameraManager)
                            .grayscale(settings.isBlackAndWhiteMode ? 1.0 : 0.0)
                            .aspectRatio(3.0 / 4.0, contentMode: .fit)
                            .clipped()
                        
                        if let capturedImage = cameraManager.latestCapturedImage {
                            FlyToCornerAnimationView(image: capturedImage) {
                                cameraManager.latestCapturedImage = nil
                            }
                        }
                    }
                    
                    Spacer(minLength: 0)
                    
                    // Optional Develop Mode action button
                    if settings.isDevelopModeEnabled {
                        Button(action: {
                            HapticManager.medium()
                            let count = filmManager.activeRollPhotoCount
                            developAlertMessage = "Are you sure? You took \(count) pictures. You can only get one roll of pictures for today."
                            isShowingDevelopAlert = true
                        }) {
                            HStack(spacing: 8) {
                                Image(systemName: "shippingbox.fill")
                                    .font(.system(size: 14, weight: .bold))
                                Text("Send to develop (\(filmManager.activeRollPhotoCount))")
                                    .font(.system(size: 14, weight: .bold))
                            }
                            .foregroundColor(.white)
                            .padding(.horizontal, 20)
                            .padding(.vertical, 10)
                            .background(Color.red)
                            .cornerRadius(20)
                        }
                        .padding(.bottom, 12)
                    }
                    
                    // Bottom Controls Bar
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
        .sheet(isPresented: $isShowingSettings) {
            SettingsView()
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
