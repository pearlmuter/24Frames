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
    private var initialVolume: Float = 0.0
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
        
        initialVolume = audioSession.outputVolume
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(volumeDidChange(_:)),
            name: NSNotification.Name("AVSystemController_SystemVolumeDidChangeNotification"),
            object: nil
        )
        
        observation = audioSession.observe(\.outputVolume, options: [.new, .old]) { [weak self] session, change in
            DispatchQueue.main.async {
                self?.onVolumeButtonTap?()
            }
        }
    }
    
    @objc private func volumeDidChange(_ notification: Notification) {
        DispatchQueue.main.async {
            self.onVolumeButtonTap?()
        }
    }
    
    public func stopListening() {
        observation?.invalidate()
        observation = nil
        NotificationCenter.default.removeObserver(self)
        DispatchQueue.main.async {
            self.volumeView.removeFromSuperview()
        }
    }
}
