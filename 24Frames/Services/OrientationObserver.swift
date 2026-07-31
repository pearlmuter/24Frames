import SwiftUI
import Combine
import UIKit

public class OrientationObserver: ObservableObject {
    @Published public var orientation: UIDeviceOrientation = .portrait
    @Published public var rotationAngle: Double = 0.0
    
    private var cancellable: AnyCancellable?
    
    public init() {
        startListening()
    }
    
    public func startListening() {
        UIDevice.current.beginGeneratingDeviceOrientationNotifications()
        
        cancellable = NotificationCenter.default
            .publisher(for: UIDevice.orientationDidChangeNotification)
            .compactMap { _ in UIDevice.current.orientation }
            .filter { $0.isValidInterfaceOrientation }
            .sink { [weak self] newOrientation in
                DispatchQueue.main.async {
                    self?.updateOrientation(newOrientation)
                }
            }
        
        updateOrientation(UIDevice.current.orientation)
    }
    
    private func updateOrientation(_ newOrientation: UIDeviceOrientation) {
        self.orientation = newOrientation
        switch newOrientation {
        case .landscapeLeft:
            self.rotationAngle = 90.0
        case .landscapeRight:
            self.rotationAngle = -90.0
        case .portraitUpsideDown:
            self.rotationAngle = 180.0
        default:
            self.rotationAngle = 0.0
        }
    }
    
    deinit {
        cancellable?.cancel()
        UIDevice.current.endGeneratingDeviceOrientationNotifications()
    }
}
