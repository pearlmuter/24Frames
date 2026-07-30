import UIKit
import AVFoundation
import MediaPlayer
import SwiftUI

public class VolumeButtonObserver: NSObject, ObservableObject {
    private var isListening = false
    private var isKVOAdded = false
    
    public var onVolumeButtonTap: (() -> Void)?
    
    public override init() {
        super.init()
    }
    
    public func startListening() {
        guard !isListening else { return }
        isListening = true
        
        let audioSession = AVAudioSession.sharedInstance()
        do {
            try audioSession.setCategory(.playback, options: .mixWithOthers)
            try audioSession.setActive(true)
        } catch {
            print("Audio session configuration error: \(error)")
        }
        
        if !isKVOAdded {
            audioSession.addObserver(self, forKeyPath: "outputVolume", options: [.new, .old], context: nil)
            isKVOAdded = true
        }
    }
    
    public func stopListening() {
        guard isListening else { return }
        isListening = false
        if isKVOAdded {
            AVAudioSession.sharedInstance().removeObserver(self, forKeyPath: "outputVolume")
            isKVOAdded = false
        }
    }
    
    public override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        if keyPath == "outputVolume" {
            guard isListening else { return }
            DispatchQueue.main.async { [weak self] in
                self?.onVolumeButtonTap?()
            }
        }
    }
    
    deinit {
        stopListening()
    }
}

public struct VolumeViewHidden: UIViewRepresentable {
    public init() {}
    public func makeUIView(context: Context) -> MPVolumeView {
        let volumeView = MPVolumeView(frame: CGRect(x: -100, y: -100, width: 1, height: 1))
        volumeView.alpha = 0.0001
        volumeView.clipsToBounds = true
        return volumeView
    }
    public func updateUIView(_ uiView: MPVolumeView, context: Context) {}
}
