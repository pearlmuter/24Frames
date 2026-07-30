import SwiftUI

public struct ShutterRingView: View {
    @Binding public var isAnimating: Bool
    
    public init(isAnimating: Binding<Bool>) {
        self._isAnimating = isAnimating
    }
    
    public var body: some View {
        GeometryReader { geometry in
            ZStack {
                if isAnimating {
                    Circle()
                        .stroke(Color.white, lineWidth: 3)
                        .scaleEffect(isAnimating ? 3.5 : 0.2)
                        .opacity(isAnimating ? 0.0 : 0.9)
                        .animation(.easeOut(duration: 0.35), value: isAnimating)
                        .position(x: geometry.size.width / 2, y: geometry.size.height / 2)
                }
            }
        }
        .allowsHitTesting(false)
        .accessibilityIdentifier("ShutterRingAnimation")
    }
}
