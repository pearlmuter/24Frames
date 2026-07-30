import UIKit
import AVFoundation
import MediaPlayer
import Combine
import SwiftUI

public class VolumeButtonObserver: ObservableObject {
    private var cancellable: AnyCancellable?
    private var isListening = false
    
    public var onVolumeButtonTap: (() -> Void)?
    
    public init() {}
    
    public func startListening() {
        guard !isListening else { return }
        isListening = true
        
        let audioSession = AVAudioSession.sharedInstance()
        do {
            try audioSession.setCategory(.ambient, options: .mixWithOthers)
            try audioSession.setActive(true)
        } catch {
            print("Audio session configuration error: \(error)")
        }
        
        cancellable = audioSession.publisher(for: \.outputVolume)
            .dropFirst()
            .sink { [weak self] _ in
                guard let self = self, self.isListening else { return }
                self.onVolumeButtonTap?()
            }
    }
    
    public func stopListening() {
        isListening = false
        cancellable?.cancel()
    }
}

public struct VolumeViewHidden: UIViewRepresentable {
    public init() {}
    public func makeUIView(context: Context) -> MPVolumeView {
        let volumeView = MPVolumeView(frame: CGRect(x: -100, y: -100, width: 1, height: 1))
        volumeView.alpha = 0.0001
        return volumeView
    }
    public func updateUIView(_ uiView: MPVolumeView, context: Context) {}
}
