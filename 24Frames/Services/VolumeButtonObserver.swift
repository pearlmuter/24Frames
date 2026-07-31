import UIKit
import SwiftUI
import AVFoundation
import MediaPlayer

public struct VolumeViewHidden: UIViewRepresentable {
    public init() {}
    public func makeUIView(context: Context) -> MPVolumeView {
        let view = MPVolumeView(frame: .zero)
        view.alpha = 0.0001
        return view
    }
    public func updateUIView(_ uiView: MPVolumeView, context: Context) {}
}

public class VolumeButtonObserver: ObservableObject {
    public var onVolumeButtonTap: (() -> Void)?
    
    private var observation: NSKeyValueObservation?
    private var lastVolume: Float = -1.0
    private lazy var volumeView: MPVolumeView = {
        let view = MPVolumeView(frame: CGRect(x: -1000, y: -1000, width: 1, height: 1))
        view.isHidden = false
        view.alpha = 0.0001
        return view
    }()
    
    public init() {}
    
    public func startListening() {
        let audioSession = AVAudioSession.sharedInstance()
        do {
            try audioSession.setCategory(.playback, options: [.mixWithOthers])
            try audioSession.setActive(true)
        } catch {
            print("VolumeButtonObserver error setting audio session: \(error)")
        }
        
        DispatchQueue.main.async {
            if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
               let window = windowScene.windows.first {
                if !window.subviews.contains(self.volumeView) {
                    window.addSubview(self.volumeView)
                }
            }
        }
        
        lastVolume = audioSession.outputVolume
        
        // Single KVO observer to prevent duplicate volume button callbacks
        observation = audioSession.observe(\.outputVolume, options: [.new]) { [weak self] session, change in
            guard let self = self, let newVolume = change.newValue else { return }
            if abs(newVolume - self.lastVolume) > 0.001 {
                self.lastVolume = newVolume
                DispatchQueue.main.async {
                    self.onVolumeButtonTap?()
                }
            }
        }
    }
    
    public func stopListening() {
        observation?.invalidate()
        observation = nil
        DispatchQueue.main.async {
            self.volumeView.removeFromSuperview()
        }
    }
}
